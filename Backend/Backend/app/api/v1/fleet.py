from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from uuid import UUID

from app.database import SessionLocal
from app.models import User, Shuttle, DriverCurrentRoute
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
