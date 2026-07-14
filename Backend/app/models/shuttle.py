import uuid
from datetime import datetime
from enum import Enum
from sqlalchemy import Column, String, Integer, DateTime, Enum as SQLEnum, ForeignKey, UUID as UUID_TYPE
from sqlalchemy.dialects.postgresql import UUID
from app.database import Base


class ShuttleStatus(str, Enum):
    active = "active"
    idle = "idle"
    offline = "offline"


class Shuttle(Base):
    __tablename__ = "shuttles"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    name = Column(String, nullable=False)
    plate_number = Column(String, unique=True, nullable=False)
    capacity = Column(Integer, nullable=False)
    status = Column(SQLEnum(ShuttleStatus), nullable=False)
    driver_id = Column(UUID(as_uuid=True), ForeignKey("users.id"), nullable=True)
    created_at = Column(DateTime, default=datetime.utcnow)
