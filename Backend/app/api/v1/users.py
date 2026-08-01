"""User account management endpoints."""
from fastapi import APIRouter, Depends, HTTPException
from pydantic import BaseModel
from sqlalchemy.orm import Session

from app.database import SessionLocal
from app.models import User
from app.schemas.user import UserResponse
from app.api.deps import get_db, get_current_user

router = APIRouter(prefix="/api/v1/users", tags=["users"])


class FCMTokenRequest(BaseModel):
    fcm_token: str


class UpdateUserRequest(BaseModel):
    name: str


@router.post("/fcm-token")
def register_fcm_token(
    request: FCMTokenRequest,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """Register/update FCM token for push notifications."""
    # Refresh to get latest state
    db.refresh(current_user)

    # Update FCM token
    current_user.fcm_token = request.fcm_token
    db.commit()
    db.refresh(current_user)

    return {
        "message": "FCM token updated successfully",
        "user_id": str(current_user.id),
        "fcm_token_registered": current_user.fcm_token is not None
    }


@router.put("/me", response_model=UserResponse)
def update_current_user(
    request: UpdateUserRequest,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """Update current user's name (email updates out of scope for now)."""
    current_user.name = request.name
    db.commit()
    db.refresh(current_user)
    return current_user


@router.get("/me", response_model=UserResponse)
def get_current_user_info(
    current_user: User = Depends(get_current_user),
):
    """Get current user information."""
    return current_user
