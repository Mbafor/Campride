from fastapi import APIRouter, Depends, HTTPException, Query
from sqlalchemy.orm import Session
from sqlalchemy import func
from uuid import UUID
from datetime import date

from app.database import SessionLocal
from app.models import User, Shuttle, DriverCurrentRoute, RideHistory, Trip, Route
from app.schemas.shuttle import ShuttleResponse
from app.api.deps import get_db, get_current_user, require_role

router = APIRouter(prefix="/api/v1/fleet", tags=["fleet"])


@router.get("/drivers", response_model=list[dict])
def list_drivers(
    current_user: User = Depends(require_role(["fleet_manager", "super_admin"])),
    db: Session = Depends(get_db),
):
    """List all drivers with their current shuttle and route assignments"""
    drivers = db.query(User).filter(User.role == "driver").all()

    result = []
    for driver in drivers:
        shuttle = db.query(Shuttle).filter(Shuttle.driver_id == driver.id).first()
        route_assignment = db.query(DriverCurrentRoute).filter(DriverCurrentRoute.driver_id == driver.id).first()

        result.append({
            "id": driver.id,
            "name": driver.name,
            "email": driver.email,
            "is_active": driver.is_active,
            "assigned_shuttle": {
                "id": shuttle.id,
                "name": shuttle.name,
                "plate_number": shuttle.plate_number,
                "status": shuttle.status,
            } if shuttle else None,
            "assigned_route": {
                "id": route_assignment.route.id,
                "name": route_assignment.route.name,
            } if route_assignment and route_assignment.route else None,
        })

    return result


@router.get("/drivers/{driver_id}", response_model=dict)
def get_driver_details(
    driver_id: UUID,
    current_user: User = Depends(require_role(["fleet_manager", "super_admin"])),
    db: Session = Depends(get_db),
):
    """Get one driver's details including shuttle and route assignments"""
    driver = db.query(User).filter(User.id == driver_id, User.role == "driver").first()
    if not driver:
        raise HTTPException(status_code=404, detail="Driver not found")

    shuttle = db.query(Shuttle).filter(Shuttle.driver_id == driver.id).first()
    route_assignment = db.query(DriverCurrentRoute).filter(DriverCurrentRoute.driver_id == driver.id).first()

    return {
        "id": driver.id,
        "name": driver.name,
        "email": driver.email,
        "is_active": driver.is_active,
        "created_at": driver.created_at,
        "assigned_shuttle": {
            "id": shuttle.id,
            "name": shuttle.name,
            "plate_number": shuttle.plate_number,
            "capacity": shuttle.capacity,
            "status": shuttle.status,
        } if shuttle else None,
        "assigned_route": {
            "id": route_assignment.route.id,
            "name": route_assignment.route.name,
        } if route_assignment and route_assignment.route else None,
    }


@router.get("/shuttles", response_model=list[dict])
def list_all_shuttles(
    current_user: User = Depends(require_role(["fleet_manager", "super_admin"])),
    db: Session = Depends(get_db),
):
    """List all shuttles with driver assignments and status"""
    shuttles = db.query(Shuttle).all()

    result = []
    for shuttle in shuttles:
        driver = db.query(User).filter(User.id == shuttle.driver_id).first() if shuttle.driver_id else None

        result.append({
            "id": shuttle.id,
            "name": shuttle.name,
            "plate_number": shuttle.plate_number,
            "capacity": shuttle.capacity,
            "status": shuttle.status,
            "assigned_driver": {
                "id": driver.id,
                "name": driver.name,
                "email": driver.email,
            } if driver else None,
        })

    return result


@router.get("/drivers/{driver_id}/rides")
def get_driver_rides(
    driver_id: UUID,
    target_date: date = Query(None, alias="date", description="Date in YYYY-MM-DD format. Defaults to today."),
    current_user: User = Depends(require_role(["fleet_manager", "super_admin"])),
    db: Session = Depends(get_db),
):
    """
    Get all rides for a specific driver on a specific date.
    Fleet managers/admins can view any driver's ride data.
    """
    # Verify driver exists
    driver = db.query(User).filter(User.id == driver_id, User.role == "driver").first()
    if not driver:
        raise HTTPException(status_code=404, detail="Driver not found")

    if target_date is None:
        target_date = date.today()

    # Query rides for this driver on this date
    rides = db.query(
        RideHistory.id,
        RideHistory.boarded_at,
        RideHistory.alighted_at,
        Route.name.label("route_name"),
        Shuttle.name.label("shuttle_name"),
        Shuttle.plate_number.label("shuttle_plate"),
        RideHistory.created_at,
    ).join(
        Trip, RideHistory.trip_id == Trip.id
    ).join(
        Route, Trip.route_id == Route.id
    ).join(
        Shuttle, Trip.shuttle_id == Shuttle.id
    ).filter(
        Trip.driver_id == driver_id,
        Trip.status == "completed",
        func.date(Trip.ended_at) == target_date
    ).order_by(
        RideHistory.boarded_at.asc()
    ).all()

    ride_list = []
    for ride in rides:
        duration_seconds = None
        if ride.boarded_at and ride.alighted_at:
            duration = ride.alighted_at - ride.boarded_at
            duration_seconds = int(duration.total_seconds())

        ride_list.append({
            "ride_id": str(ride.id),
            "route_name": ride.route_name,
            "shuttle_name": ride.shuttle_name,
            "shuttle_plate": ride.shuttle_plate,
            "boarded_at": ride.boarded_at.isoformat() if ride.boarded_at else None,
            "alighted_at": ride.alighted_at.isoformat() if ride.alighted_at else None,
            "duration_seconds": duration_seconds,
            "created_at": ride.created_at.isoformat(),
        })

    return {
        "driver_id": str(driver_id),
        "driver_name": driver.name,
        "date": target_date.isoformat(),
        "total_rides": len(ride_list),
        "rides": ride_list
    }


@router.get("/drivers/{driver_id}/routes")
def get_driver_routes(
    driver_id: UUID,
    current_user: User = Depends(require_role(["fleet_manager", "super_admin"])),
    db: Session = Depends(get_db),
):
    """
    Get all distinct routes a driver has taken historically with trip counts and last used date.
    Fleet managers/admins can view any driver's route history.
    """
    # Verify driver exists
    driver = db.query(User).filter(User.id == driver_id, User.role == "driver").first()
    if not driver:
        raise HTTPException(status_code=404, detail="Driver not found")

    # Query completed trips and group by route
    trips = db.query(
        Trip.route_id,
        Route.name.label("route_name"),
        func.count(Trip.id).label("trip_count"),
        func.max(Trip.ended_at).label("last_used"),
    ).join(
        Route, Trip.route_id == Route.id
    ).filter(
        Trip.driver_id == driver_id,
        Trip.status == "completed"
    ).group_by(
        Trip.route_id, Route.name
    ).order_by(
        func.max(Trip.ended_at).desc()
    ).all()

    routes = [
        {
            "route_name": trip.route_name,
            "trip_count": trip.trip_count,
            "last_used": trip.last_used.isoformat() if trip.last_used else None,
        }
        for trip in trips
    ]

    return {
        "driver_id": str(driver_id),
        "driver_name": driver.name,
        "total_distinct_routes": len(routes),
        "routes": routes
    }
