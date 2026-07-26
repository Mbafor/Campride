from uuid import UUID
from datetime import datetime
from pydantic import BaseModel


class NotificationResponse(BaseModel):
    id: UUID
    type: str
    message: str
    is_read: bool
    created_at: datetime
    trip_id: UUID | None = None

    class Config:
        from_attributes = True


class NotificationListResponse(BaseModel):
    notifications: list[NotificationResponse]
