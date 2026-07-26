from fastapi import APIRouter, Depends, HTTPException, Query
from sqlalchemy.orm import Session
from uuid import UUID
from pydantic import BaseModel
from datetime import datetime, date
from sqlalchemy import func

from app.database import SessionLocal
from app.models import User, Route, DriverCurrentRoute, Shuttle, Trip, RideHistory
from app.schemas.route import RouteResponse
from app.schemas.shuttle import ShuttleResponse
from app.api.deps import get_db, get_current_user, require_role
from app.core.redis_client import remove_driver_location

router = APIRouter(prefix="/api/v1/driver", tags=["driver"])


class DriverRouteRequest(BaseModel):
    route_id: UUID


def close_active_trip(driver_id: str | UUID, db: Session) -> dict:
    """
    Find driver's active trip and mark it as completed.
    Automatically sets alighted_at for any RideHistory records in that trip.
    Returns dict with trip_id (if closed) or None (if no active trip).
    Used by both /driver/offline endpoint and stale cleanup task.
    """
    from uuid import UUID
    if isinstance(driver_id, str):
        driver_id = UUID(driver_id)

    active_trip = db.query(Trip).filter(
        Trip.driver_id == driver_id,
        Trip.status == "active"
    ).first()

    if active_trip:
        active_trip.status = "completed"
        active_trip.ended_at = datetime.utcnow()
        db.commit()
        db.refresh(active_trip)

        # Automatically set alighted_at for any open ride histories on this trip
        open_rides = db.query(RideHistory).filter(
            RideHistory.trip_id == active_trip.id,
            RideHistory.alighted_at == None
        ).all()

        for ride in open_rides:
            ride.alighted_at = active_trip.ended_at

        if open_rides:
            db.commit()

        return {
            "closed": True,
            "trip_id": str(active_trip.id),
            "ended_at": active_trip.ended_at.isoformat(),
            "rides_closed": len(open_rides)
        }
    else:
        return {
            "closed": False,
            "trip_id": None
        }


@router.get("/route", response_model=dict | None)
def get_driver_route(
    current_user: User = Depends(require_role(["driver"])),
    db: Session = Depends(get_db),
):
    """Get the driver's currently assigned/active route"""
    driver_route = db.query(DriverCurrentRoute).filter(DriverCurrentRoute.driver_id == current_user.id).first()
    if not driver_route or not driver_route.route:
        return None

    return RouteResponse.from_orm_with_geometry(driver_route.route)


@router.put("/route")
def update_driver_route(
    request: DriverRouteRequest,
    current_user: User = Depends(require_role(["driver"])),
    db: Session = Depends(get_db),
):
    """Update the driver's route selection (persists until explicitly changed)"""
    route = db.query(Route).filter(Route.id == request.route_id).first()
    if not route:
        raise HTTPException(status_code=404, detail="Route not found")

    driver_route = db.query(DriverCurrentRoute).filter(DriverCurrentRoute.driver_id == current_user.id).first()
    if driver_route:
        driver_route.route_id = request.route_id
        db.commit()
        db.refresh(driver_route)
    else:
        new_driver_route = DriverCurrentRoute(
            driver_id=current_user.id,
            route_id=request.route_id,
        )
        db.add(new_driver_route)
        db.commit()
        db.refresh(new_driver_route)

    return {
        "message": "Route updated successfully",
        "route": RouteResponse.from_orm_with_geometry(route),
    }


@router.get("/shuttle", response_model=ShuttleResponse)
def get_driver_shuttle(
    current_user: User = Depends(require_role(["driver"])),
    db: Session = Depends(get_db),
):
    """Get the driver's currently assigned shuttle"""
    shuttle = db.query(Shuttle).filter(Shuttle.driver_id == current_user.id).first()
    if not shuttle:
        raise HTTPException(
            status_code=404,
            detail="No shuttle currently assigned to this driver"
        )
    return shuttle


@router.post("/offline")
def driver_offline(
    current_user: User = Depends(require_role(["driver"])),
    db: Session = Depends(get_db),
):
    """End driver's shift: remove from live tracking and close active trip"""
    driver_id_str = str(current_user.id)

    # Remove driver from Redis live tracking
    remove_driver_location(driver_id_str)

    # Find and close their active trip
    trip_result = close_active_trip(current_user.id, db)

    if trip_result["closed"]:
        return {
            "status": "success",
            "message": "Driver removed from live tracking and trip closed",
            "trip_id": trip_result["trip_id"],
            "trip_ended_at": trip_result["ended_at"]
        }
    else:
        return {
            "status": "success",
            "message": "Driver removed from live tracking. No active trip to close.",
            "trip_id": None
        }


@router.get("/trips/summary")
def get_trip_summary(
    target_date: date = Query(None, description="Date in YYYY-MM-DD format. Defaults to today."),
    current_user: User = Depends(require_role(["driver"])),
    db: Session = Depends(get_db),
):
    """
    Get trip summary for driver for a specific date.
    Returns total completed trips and route breakdown.
    """
    if target_date is None:
        target_date = date.today()

    # Query completed trips for this driver on this date
    trips = db.query(Trip).filter(
        Trip.driver_id == current_user.id,
        Trip.status == "completed",
        func.date(Trip.ended_at) == target_date
    ).all()

    total_trips = len(trips)

    # Count trips by route
    route_counts = {}
    for trip in trips:
        if trip.route_id:
            route = db.query(Route).filter(Route.id == trip.route_id).first()
            if route:
                route_name = route.name
                route_counts[route_name] = route_counts.get(route_name, 0) + 1

    routes = [
        {"route_name": route_name, "count": count}
        for route_name, count in sorted(route_counts.items())
    ]

    return {
        "date": target_date.isoformat(),
        "total_completed_trips": total_trips,
        "routes": routes
    }
