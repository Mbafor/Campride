"""Student endpoints — ride history and related data."""
from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session
from sqlalchemy import func

from app.database import SessionLocal
from app.models import RideHistory, Trip, Route, Shuttle, User
from app.api.deps import get_db, get_current_user

router = APIRouter(prefix="/api/v1/students", tags=["students"])


@router.get("/me/rides")
def list_my_rides(
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """
    List current student's ride history, most recent first.
    Joins with Trip, Route, and Shuttle to show route name, shuttle info.
    Calculates duration (alighted_at - boarded_at).
    """
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
        RideHistory.student_id == current_user.id
    ).order_by(
        RideHistory.created_at.desc()
    ).all()

    ride_list = []
    for ride in rides:
        # Calculate duration if both boarded_at and alighted_at exist
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
        "rides": ride_list,
        "total": len(ride_list)
    }
