from uuid import UUID
from datetime import datetime
from typing import Optional
from pydantic import BaseModel


class SupportTicketRequest(BaseModel):
    type: str
    title: Optional[str] = None
    message: Optional[str] = None
    rating: Optional[int] = None
    screenshot_data_url: Optional[str] = None


class SupportTicketResponse(BaseModel):
    id: UUID
    type: str
    title: Optional[str] = None
    message: Optional[str] = None
    rating: Optional[int] = None
    screenshot_url: Optional[str] = None
    status: str
    created_at: datetime

    class Config:
        from_attributes = True
