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
    name: str | None = None
    gender: str | None = None
    phone_number: str | None = None
    email: str | None = None


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
    """Update current user's profile fields (name, gender, phone number, email)."""
    if request.name is not None:
        current_user.name = request.name
    if request.gender is not None:
        current_user.gender = request.gender
    if request.phone_number is not None:
        current_user.phone_number = request.phone_number
    if request.email is not None:
        # Don't allow taking an email that's already used by another account
        existing = db.query(User).filter(User.email == request.email, User.id != current_user.id).first()
        if existing:
            raise HTTPException(
                status_code=409,
                detail={"error_code": "AUTH_002", "message": "Email already in use"}
            )
        current_user.email = request.email
    db.commit()
    db.refresh(current_user)
    return current_user


@router.get("/me", response_model=UserResponse)
def get_current_user_info(
    current_user: User = Depends(get_current_user),
):
    """Get current user information."""
    return current_user
