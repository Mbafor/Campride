import uuid
from datetime import datetime
from sqlalchemy import Column, DateTime, ForeignKey
from sqlalchemy.dialects.postgresql import UUID
from app.database import Base


class RideHistory(Base):
    __tablename__ = "ride_histories"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    student_id = Column(UUID(as_uuid=True), ForeignKey("users.id"), nullable=False)
    trip_id = Column(UUID(as_uuid=True), ForeignKey("trips.id"), nullable=False)
    shuttle_request_id = Column(UUID(as_uuid=True), ForeignKey("shuttle_requests.id"), nullable=True)
    boarded_at = Column(DateTime, nullable=True)
    alighted_at = Column(DateTime, nullable=True)
    created_at = Column(DateTime, default=datetime.utcnow)
