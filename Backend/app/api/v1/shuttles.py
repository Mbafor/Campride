from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from uuid import UUID

from app.database import SessionLocal
from app.models import Shuttle, User, DriverCurrentRoute, ShuttleRequest, ShuttleRequestStatus, Trip
from app.schemas.shuttle import (
    ShuttleCreate, ShuttleUpdate, ShuttleResponse, AssignDriverRequest,
    ShuttleMatchRequest, ShuttleMatchResponse
)
from app.api.deps import get_db, get_current_user, require_role
from app.core.shuttle_matching import find_matched_shuttles, find_nearby_shuttles
from geoalchemy2.elements import WKTElement
from uuid import uuid4

admin_router = APIRouter(prefix="/api/v1/admin/shuttles", tags=["admin-shuttles"])
public_router = APIRouter(prefix="/api/v1/shuttles", tags=["shuttles"])


@admin_router.post("", response_model=ShuttleResponse)
def create_shuttle(
    shuttle_data: ShuttleCreate,
    current_user: User = Depends(require_role(["super_admin", "fleet_manager"])),
    db: Session = Depends(get_db),
):
    existing = db.query(Shuttle).filter(Shuttle.plate_number == shuttle_data.plate_number).first()
    if existing:
        raise HTTPException(status_code=409, detail="Shuttle with this plate number already exists")

    new_shuttle = Shuttle(
        name=shuttle_data.name,
        plate_number=shuttle_data.plate_number,
        capacity=shuttle_data.capacity,
        status="idle",
    )
    db.add(new_shuttle)
    db.commit()
    db.refresh(new_shuttle)
    return new_shuttle


@admin_router.get("", response_model=list[ShuttleResponse])
def list_shuttles(
    current_user: User = Depends(require_role(["super_admin"])),
    db: Session = Depends(get_db),
):
    shuttles = db.query(Shuttle).all()
    return shuttles


@admin_router.get("/{shuttle_id}", response_model=ShuttleResponse)
def get_shuttle(
    shuttle_id: UUID,
    current_user: User = Depends(require_role(["super_admin"])),
    db: Session = Depends(get_db),
):
    shuttle = db.query(Shuttle).filter(Shuttle.id == shuttle_id).first()
    if not shuttle:
        raise HTTPException(status_code=404, detail="Shuttle not found")
    return shuttle


@admin_router.put("/{shuttle_id}", response_model=ShuttleResponse)
def update_shuttle(
    shuttle_id: UUID,
    shuttle_data: ShuttleUpdate,
    current_user: User = Depends(require_role(["super_admin", "fleet_manager"])),
    db: Session = Depends(get_db),
):
    shuttle = db.query(Shuttle).filter(Shuttle.id == shuttle_id).first()
    if not shuttle:
        raise HTTPException(status_code=404, detail="Shuttle not found")

    if shuttle_data.plate_number and shuttle_data.plate_number != shuttle.plate_number:
        existing = db.query(Shuttle).filter(Shuttle.plate_number == shuttle_data.plate_number).first()
        if existing:
            raise HTTPException(status_code=409, detail="Shuttle with this plate number already exists")

    if shuttle_data.name is not None:
        shuttle.name = shuttle_data.name
    if shuttle_data.plate_number is not None:
        shuttle.plate_number = shuttle_data.plate_number
    if shuttle_data.capacity is not None:
        shuttle.capacity = shuttle_data.capacity
    if shuttle_data.status is not None:
        shuttle.status = shuttle_data.status
    if shuttle_data.driver_id is not None:
        shuttle.driver_id = shuttle_data.driver_id

    db.commit()
    db.refresh(shuttle)
    return shuttle


@admin_router.delete("/{shuttle_id}")
def delete_shuttle(
    shuttle_id: UUID,
    current_user: User = Depends(require_role(["super_admin", "fleet_manager"])),
    db: Session = Depends(get_db),
):
    shuttle = db.query(Shuttle).filter(Shuttle.id == shuttle_id).first()
    if not shuttle:
        raise HTTPException(status_code=404, detail="Shuttle not found")

    db.delete(shuttle)
    db.commit()
    return {"message": "Shuttle deleted successfully"}


@admin_router.put("/{shuttle_id}/assign-driver")
def assign_driver(
    shuttle_id: UUID,
    request: AssignDriverRequest,
    current_user: User = Depends(require_role(["super_admin", "fleet_manager"])),
    db: Session = Depends(get_db),
):
    shuttle = db.query(Shuttle).filter(Shuttle.id == shuttle_id).first()
    if not shuttle:
        raise HTTPException(status_code=404, detail="Shuttle not found")

    driver = db.query(User).filter(User.id == request.driver_id, User.role == "driver").first()
    if not driver:
        raise HTTPException(status_code=404, detail="Driver not found or user is not a driver")

    shuttle.driver_id = request.driver_id
    db.commit()
    db.refresh(shuttle)
    return {"message": "Driver assigned successfully", "shuttle": ShuttleResponse.from_orm(shuttle)}


@public_router.get("", response_model=list[ShuttleResponse])
def list_all_shuttles(
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    shuttles = db.query(Shuttle).all()
    return shuttles


@public_router.post("/match", response_model=ShuttleMatchResponse)
def match_shuttles(
    request: ShuttleMatchRequest,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """Find shuttles matching a pickup/destination pair."""
    try:
        matched = find_matched_shuttles(
            request.pickup_lat,
            request.pickup_lng,
            request.destination_lat,
            request.destination_lng,
            db,
            proximity_threshold_meters=300
        )

        nearby_exclude_ids = [m['driver_id'] for m in matched]
        nearby = find_nearby_shuttles(
            request.pickup_lat,
            request.pickup_lng,
            db,
            exclude_driver_ids=nearby_exclude_ids,
            radius_meters=1000
        )

        # Create/update ShuttleRequest record
        pickup_point = WKTElement(f"POINT({request.pickup_lng} {request.pickup_lat})", srid=4326)
        destination_point = WKTElement(f"POINT({request.destination_lng} {request.destination_lat})", srid=4326)

        shuttle_request = ShuttleRequest(
            id=uuid4(),
            student_id=current_user.id,
            pickup_location=pickup_point,
            destination_location=destination_point,
            status=ShuttleRequestStatus.matched if matched else ShuttleRequestStatus.pending,
            matched_trip_id=None,
            last_notification_level=None
        )

        # If there are matches, pick the best one (soonest ETA)
        if matched:
            best_match = min(matched, key=lambda m: m['eta_minutes'])

            # Look up the active trip for this driver
            active_trip = db.query(Trip).filter(
                Trip.driver_id == best_match['driver_id'],
                Trip.status == "active"
            ).first()

            if active_trip:
                shuttle_request.matched_trip_id = active_trip.id
                print(f"[Match] Created ShuttleRequest {shuttle_request.id} for student {current_user.id}")
                print(f"[Match] Best match: {best_match['shuttle_name']} with ETA {best_match['eta_minutes']}min, trip_id={active_trip.id}")
            else:
                print(f"[Match] Created ShuttleRequest {shuttle_request.id} for student {current_user.id}")
                print(f"[Match] Best match: {best_match['shuttle_name']} with ETA {best_match['eta_minutes']}min, but no active trip found")
        else:
            print(f"[Match] Created ShuttleRequest {shuttle_request.id} for student {current_user.id} with status=pending (no matches)")

        db.add(shuttle_request)
        db.commit()
        db.refresh(shuttle_request)

        return ShuttleMatchResponse(matched=matched, nearby=nearby)
    except Exception as e:
        print(f"[Match Endpoint] Error: {e}")
        raise HTTPException(status_code=500, detail=f"Matching error: {str(e)}")


@public_router.post("/match/debug")
def match_shuttles_debug(
    request: ShuttleMatchRequest,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """Debug version of matching that returns logs and calculations."""
    import io
    import sys

    # Capture stdout
    log_capture = io.StringIO()
    old_stdout = sys.stdout
    sys.stdout = log_capture

    try:
        matched = find_matched_shuttles(
            request.pickup_lat,
            request.pickup_lng,
            request.destination_lat,
            request.destination_lng,
            db,
            proximity_threshold_meters=300
        )

        nearby_exclude_ids = [m['driver_id'] for m in matched]
        nearby = find_nearby_shuttles(
            request.pickup_lat,
            request.pickup_lng,
            db,
            exclude_driver_ids=nearby_exclude_ids,
            radius_meters=1000
        )

        logs = log_capture.getvalue()

        return {
            "matched": matched,
            "nearby": nearby,
            "debug_logs": logs
        }
    finally:
        sys.stdout = old_stdout
