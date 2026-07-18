from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from uuid import UUID

from app.database import SessionLocal
from app.models import Shuttle, User, DriverCurrentRoute
from app.schemas.shuttle import ShuttleCreate, ShuttleUpdate, ShuttleResponse, AssignDriverRequest
from app.api.deps import get_db, get_current_user, require_role

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
