from uuid import UUID
from datetime import datetime
from pydantic import BaseModel
from enum import Enum


class ShuttleStatus(str, Enum):
    active = "active"
    idle = "idle"
    offline = "offline"


class ShuttleCreate(BaseModel):
    name: str
    plate_number: str
    capacity: int


class ShuttleUpdate(BaseModel):
    name: str | None = None
    plate_number: str | None = None
    capacity: int | None = None
    status: ShuttleStatus | None = None


class AssignDriverRequest(BaseModel):
    driver_id: UUID


class ShuttleResponse(BaseModel):
    id: UUID
    name: str
    plate_number: str
    capacity: int
    status: ShuttleStatus
    driver_id: UUID | None
    created_at: datetime

    class Config:
        from_attributes = True
