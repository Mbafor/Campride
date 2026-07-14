import uuid
from datetime import datetime
from enum import Enum
from sqlalchemy import Column, String, DateTime, Enum as SQLEnum, ForeignKey
from sqlalchemy.dialects.postgresql import UUID
from geoalchemy2 import Geometry
from app.database import Base


class ShuttleRequestStatus(str, Enum):
    pending = "pending"
    matched = "matched"
    completed = "completed"
    cancelled = "cancelled"


class ShuttleRequest(Base):
    __tablename__ = "shuttle_requests"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    student_id = Column(UUID(as_uuid=True), ForeignKey("users.id"), nullable=False)
    pickup_location = Column(Geometry("POINT", srid=4326), nullable=False)
    destination_location = Column(Geometry("POINT", srid=4326), nullable=False)
    pickup_name = Column(String, nullable=True)
    destination_name = Column(String, nullable=True)
    matched_trip_id = Column(UUID(as_uuid=True), ForeignKey("trips.id"), nullable=True)
    status = Column(SQLEnum(ShuttleRequestStatus), nullable=False)
    created_at = Column(DateTime, default=datetime.utcnow)
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)
