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
    driver_id: UUID | None = None


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


class ShuttleMatchRequest(BaseModel):
    pickup_lat: float
    pickup_lng: float
    destination_lat: float
    destination_lng: float


class MatchedShuttleResult(BaseModel):
    shuttle_id: str | None
    shuttle_name: str
    plate_number: str
    driver_id: str
    current_lat: float
    current_lng: float
    eta_minutes: int
    distance_meters: float
    route_name: str | None = None
    pickup_stop: str | None = None
    destination_stop: str | None = None


class NearbyShuttleResult(BaseModel):
    shuttle_id: str | None
    shuttle_name: str
    plate_number: str
    driver_id: str
    current_lat: float
    current_lng: float
    eta_minutes: int
    distance_meters: float


class ShuttleMatchResponse(BaseModel):
    shuttle_request_id: UUID | None = None
    matched: list[MatchedShuttleResult]
    nearby: list[NearbyShuttleResult]
