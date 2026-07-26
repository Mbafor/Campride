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


@router.get("")
def list_my_shuttle_requests(
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """List current user's (student's) shuttle requests, most recent first."""
    requests = db.query(ShuttleRequest).filter(
        ShuttleRequest.student_id == current_user.id
    ).order_by(ShuttleRequest.created_at.desc()).all()

    return {
        "shuttle_requests": [
            {
                "id": str(r.id),
                "status": r.status,
                "matched_trip_id": str(r.matched_trip_id) if r.matched_trip_id else None,
                "created_at": r.created_at.isoformat(),
                "updated_at": r.updated_at.isoformat() if r.updated_at else None,
            }
            for r in requests
        ]
    }


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
        raise HTTPException(status_code=404, detail={"error_code": "REQUEST_001", "message": "Shuttle request not found"})

    # Verify ownership — student can only board their own request
    if shuttle_request.student_id != current_user.id:
        raise HTTPException(
            status_code=403,
            detail={"error_code": "REQUEST_002", "message": "You can only board your own shuttle requests"}
        )

    # Verify status is "matched"
    if shuttle_request.status != ShuttleRequestStatus.matched:
        raise HTTPException(
            status_code=400,
            detail={"error_code": "REQUEST_003", "message": f"Cannot board — request status is {shuttle_request.status}, must be 'matched'"}
        )

    # Verify the request has a matched trip
    if not shuttle_request.matched_trip_id:
        raise HTTPException(
            status_code=400,
            detail={"error_code": "REQUEST_004", "message": "Shuttle request has no matched trip"}
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
