import uuid
from datetime import datetime
from sqlalchemy import Column, String, DateTime, ForeignKey
from sqlalchemy.dialects.postgresql import UUID
from app.database import Base


class FirebaseLog(Base):
    __tablename__ = "firebase_logs"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    notification_id = Column(UUID(as_uuid=True), ForeignKey("notifications.id"), nullable=True)
    user_id = Column(UUID(as_uuid=True), ForeignKey("users.id"), nullable=False)
    fcm_token = Column(String, nullable=False)
    status = Column(String, nullable=False)  # 'sent', 'failed', 'error'
    message_id = Column(String, nullable=True)  # Firebase message ID on success
    error_type = Column(String, nullable=True)  # Exception type on failure
    error_message = Column(String, nullable=True)  # Exception message
    created_at = Column(DateTime, default=datetime.utcnow)
