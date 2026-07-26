"""Shuttle request management endpoints — boarding confirmation and ride history."""
from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from uuid import UUID
from datetime import datetime

from app.database import SessionLocal
from app.models import ShuttleRequest, RideHistory, Trip, ShuttleRequestStatus
from app.api.deps import get_db, get_current_user
from app.models import User

router = APIRouter(prefix="/api/v1/shuttle-requests", tags=["shuttle-requests"])


@router.post("/{shuttle_request_id}/board")
def board_shuttle(
    shuttle_request_id: UUID,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """
    Confirm boarding for a shuttle request.
    Creates a RideHistory record with boarded_at=now.
    Only the student who made the request can confirm boarding.
    """
    # Get the shuttle request
    shuttle_request = db.query(ShuttleRequest).filter(
        ShuttleRequest.id == shuttle_request_id
    ).first()

    if not shuttle_request:
        raise HTTPException(status_code=404, detail="Shuttle request not found")

    # Verify ownership — student can only board their own request
    if shuttle_request.student_id != current_user.id:
        raise HTTPException(
            status_code=403,
            detail="You can only board your own shuttle requests"
        )

    # Verify status is "matched"
    if shuttle_request.status != ShuttleRequestStatus.matched:
        raise HTTPException(
            status_code=400,
            detail=f"Cannot board — request status is {shuttle_request.status}, must be 'matched'"
        )

    # Verify the request has a matched trip
    if not shuttle_request.matched_trip_id:
        raise HTTPException(
            status_code=400,
            detail="Shuttle request has no matched trip"
        )

    # Create RideHistory record
    ride = RideHistory(
        student_id=current_user.id,
        trip_id=shuttle_request.matched_trip_id,
        shuttle_request_id=shuttle_request.id,
        boarded_at=datetime.utcnow()
    )
    db.add(ride)

    # Update ShuttleRequest status to "completed"
    shuttle_request.status = ShuttleRequestStatus.completed
    shuttle_request.updated_at = datetime.utcnow()

    db.commit()
    db.refresh(ride)

    return {
        "ride_id": str(ride.id),
        "boarded_at": ride.boarded_at.isoformat(),
        "trip_id": str(ride.trip_id),
        "message": "Successfully boarded shuttle"
    }
