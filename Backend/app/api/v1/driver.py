from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from uuid import UUID
from pydantic import BaseModel
from datetime import datetime

from app.database import SessionLocal
from app.models import User, Route, DriverCurrentRoute, Shuttle, Trip
from app.schemas.route import RouteResponse
from app.schemas.shuttle import ShuttleResponse
from app.api.deps import get_db, get_current_user, require_role
from app.core.redis_client import remove_driver_location

router = APIRouter(prefix="/api/v1/driver", tags=["driver"])


class DriverRouteRequest(BaseModel):
    route_id: UUID


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
    active_trip = db.query(Trip).filter(
        Trip.driver_id == current_user.id,
        Trip.status == "active"
    ).first()

    if active_trip:
        active_trip.status = "completed"
        active_trip.ended_at = datetime.utcnow()
        db.commit()
        db.refresh(active_trip)
        return {
            "status": "success",
            "message": "Driver removed from live tracking and trip closed",
            "trip_id": str(active_trip.id),
            "trip_ended_at": active_trip.ended_at.isoformat()
        }
    else:
        return {
            "status": "success",
            "message": "Driver removed from live tracking. No active trip to close.",
            "trip_id": None
        }
