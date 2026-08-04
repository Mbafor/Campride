"""User account management endpoints."""
import base64

from fastapi import APIRouter, Depends, File, HTTPException, UploadFile
from pydantic import BaseModel
from sqlalchemy.orm import Session

from app.database import SessionLocal
from app.models import User
from app.schemas.user import UserResponse
from app.api.deps import get_db, get_current_user
from app.core.security import verify_password

router = APIRouter(prefix="/api/v1/users", tags=["users"])

MAX_PHOTO_BYTES = 2 * 1024 * 1024  # 2MB


class FCMTokenRequest(BaseModel):
    fcm_token: str


class UpdateUserRequest(BaseModel):
    name: str | None = None
    gender: str | None = None
    phone_number: str | None = None
    email: str | None = None


class DeleteAccountRequest(BaseModel):
    current_password: str | None = None


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


@router.post("/me/photo", response_model=UserResponse)
async def update_profile_photo(
    file: UploadFile = File(...),
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """Upload/replace the current user's profile photo.

    Stored as a base64 data URL directly on the user row rather than on
    local disk, since the API host's filesystem is not guaranteed to
    persist across deploys.
    """
    if not file.content_type or not file.content_type.startswith("image/"):
        raise HTTPException(
            status_code=400,
            detail={"error_code": "INVALID_FILE_TYPE", "message": "File must be an image"},
        )

    contents = await file.read()
    if len(contents) > MAX_PHOTO_BYTES:
        raise HTTPException(
            status_code=413,
            detail={"error_code": "FILE_TOO_LARGE", "message": "Image must be 2MB or smaller"},
        )

    encoded = base64.b64encode(contents).decode("ascii")
    current_user.photo_url = f"data:{file.content_type};base64,{encoded}"
    db.commit()
    db.refresh(current_user)
    return current_user


@router.delete("/me")
def delete_current_user(
    request: DeleteAccountRequest,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """Deactivate (soft-delete) the current user's account.

    The row is kept rather than removed since ride history and shuttle
    requests reference user_id and aren't set up to cascade. Password
    accounts must confirm their current password; Google-only accounts
    (no password set) skip that check.
    """
    if current_user.hashed_password is not None:
        if not request.current_password or not verify_password(
            request.current_password, current_user.hashed_password
        ):
            raise HTTPException(
                status_code=401,
                detail={"error_code": "AUTH_008", "message": "Current password is incorrect"}
            )

    current_user.is_active = False
    db.commit()

    return {"message": "Account deleted successfully"}
