import uuid
from datetime import datetime
from enum import Enum
from sqlalchemy import Column, String, DateTime, Text, Integer, Enum as SQLEnum, ForeignKey
from sqlalchemy.dialects.postgresql import UUID
from app.database import Base


class SupportTicketType(str, Enum):
    bug = "bug"
    feature = "feature"
    feedback = "feedback"


class SupportTicketStatus(str, Enum):
    open = "open"
    closed = "closed"


class SupportTicket(Base):
    __tablename__ = "support_tickets"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    user_id = Column(UUID(as_uuid=True), ForeignKey("users.id"), nullable=False)
    type = Column(SQLEnum(SupportTicketType), nullable=False)
    title = Column(String(200), nullable=True)
    message = Column(Text, nullable=True)
    rating = Column(Integer, nullable=True)
    screenshot_url = Column(Text, nullable=True)
    status = Column(SQLEnum(SupportTicketStatus), default=SupportTicketStatus.open, nullable=False)
    created_at = Column(DateTime, default=datetime.utcnow)
