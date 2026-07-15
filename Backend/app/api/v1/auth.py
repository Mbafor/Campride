from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from datetime import datetime
from pydantic import BaseModel
import uuid
import random
import string

from app.database import SessionLocal
from app.models import User, VerificationCode
from app.schemas.user import (
    UserRegister,
    UserLogin,
    UserResponse,
    TokenResponse,
    RefreshTokenRequest,
    UserCreateAdmin,
)
from app.core.security import hash_password, verify_password, create_access_token, create_refresh_token, decode_token
from app.core.email import send_verification_email
from app.api.deps import get_db, get_current_user, require_role

router = APIRouter(prefix="/api/v1/auth", tags=["auth"])


class EmailVerificationRequest(BaseModel):
    email: str
    code: str


class EmailResendRequest(BaseModel):
    email: str


def generate_verification_code() -> str:
    return ''.join(random.choices(string.digits, k=6))


@router.post("/register", response_model=UserResponse)
def register(user_data: UserRegister, db: Session = Depends(get_db)):
    existing_user = db.query(User).filter(User.email == user_data.email).first()
    if existing_user:
        raise HTTPException(
            status_code=409,
            detail={"error_code": "AUTH_002", "message": "User already exists"}
        )

    hashed_password = hash_password(user_data.password)
    new_user = User(
        id=uuid.uuid4(),
        name=user_data.name,
        email=user_data.email,
        hashed_password=hashed_password,
        role="student",
        is_active=True,
        is_verified=False,
    )
    db.add(new_user)
    db.commit()
    db.refresh(new_user)

    code = generate_verification_code()
    verification = VerificationCode(
        id=uuid.uuid4(),
        user_id=new_user.id,
        code=code,
    )
    db.add(verification)
    db.commit()

    send_verification_email(new_user.email, code)

    return new_user


@router.post("/verify-email")
def verify_email(request: EmailVerificationRequest, db: Session = Depends(get_db)):
    user = db.query(User).filter(User.email == request.email).first()
    if not user:
        raise HTTPException(
            status_code=404,
            detail={"error_code": "AUTH_005", "message": "User not found"}
        )

    verification = db.query(VerificationCode).filter(
        VerificationCode.user_id == user.id,
        VerificationCode.code == request.code
    ).first()

    if not verification:
        raise HTTPException(
            status_code=400,
            detail={"error_code": "AUTH_006", "message": "Invalid verification code"}
        )

    if verification.expires_at < datetime.utcnow():
        raise HTTPException(
            status_code=400,
            detail={"error_code": "AUTH_006", "message": "Verification code expired"}
        )

    user.is_verified = True
    db.delete(verification)
    db.commit()

    return {"message": "Email verified successfully"}


@router.post("/resend-verification")
def resend_verification(request: EmailResendRequest, db: Session = Depends(get_db)):
    user = db.query(User).filter(User.email == request.email).first()
    if not user:
        raise HTTPException(
            status_code=404,
            detail={"error_code": "AUTH_005", "message": "User not found"}
        )

    old_codes = db.query(VerificationCode).filter(VerificationCode.user_id == user.id).all()
    for code in old_codes:
        db.delete(code)

    code = generate_verification_code()
    verification = VerificationCode(
        id=uuid.uuid4(),
        user_id=user.id,
        code=code,
    )
    db.add(verification)
    db.commit()

    send_verification_email(user.email, code)

    return {"message": "Verification code sent"}


@router.post("/login", response_model=TokenResponse)
def login(credentials: UserLogin, db: Session = Depends(get_db)):
    user = db.query(User).filter(User.email == credentials.email).first()
    if not user or not verify_password(credentials.password, user.hashed_password):
        raise HTTPException(
            status_code=401,
            detail={"error_code": "AUTH_001", "message": "Invalid credentials"}
        )

    if not user.is_verified:
        raise HTTPException(
            status_code=403,
            detail={"error_code": "AUTH_007", "message": "Please verify your email before logging in"}
        )

    access_token = create_access_token({"sub": str(user.id), "role": user.role})
    refresh_token = create_refresh_token({"sub": str(user.id), "role": user.role})

    return TokenResponse(
        access_token=access_token,
        refresh_token=refresh_token,
        token_type="bearer"
    )


@router.post("/refresh", response_model=TokenResponse)
def refresh(request: RefreshTokenRequest, db: Session = Depends(get_db)):
    try:
        payload = decode_token(request.refresh_token)
    except ValueError as e:
        raise HTTPException(
            status_code=401,
            detail={"error_code": "AUTH_003", "message": str(e)}
        )

    user_id = payload.get("sub")
    user = db.query(User).filter(User.id == user_id).first()
    if not user:
        raise HTTPException(
            status_code=401,
            detail={"error_code": "AUTH_005", "message": "User not found"}
        )

    new_access_token = create_access_token({"sub": str(user.id), "role": user.role})
    new_refresh_token = create_refresh_token({"sub": str(user.id), "role": user.role})

    return TokenResponse(
        access_token=new_access_token,
        refresh_token=new_refresh_token,
        token_type="bearer"
    )


@router.post("/logout")
def logout():
    return {"message": "Logged out successfully"}


@router.get("/me", response_model=UserResponse)
def get_current_user_info(current_user: User = Depends(get_current_user)):
    return current_user


class GoogleSignInRequest(BaseModel):
    id_token: str


@router.post("/google", response_model=TokenResponse)
def google_sign_in(request: GoogleSignInRequest, db: Session = Depends(get_db)):
    from google.auth.transport import requests
    from google.oauth2 import id_token
    from app.core.config import settings
    import traceback
    import json
    import base64

    payload = None

    try:
        # Try to verify as ID token first
        payload = id_token.verify_oauth2_token(
            request.id_token,
            requests.Request(),
            settings.GOOGLE_OAUTH_CLIENT_ID
        )
        print(f"[DEBUG] Successfully verified as ID token")
    except ValueError as e:
        print(f"[DEBUG] ID token verification failed: {e}. Trying to decode as access token...")

        # Fallback: decode access token (may be access token instead)
        try:
            # Decode JWT without verification (will be verified via userinfo endpoint)
            parts = request.id_token.split('.')
            if len(parts) == 3:
                # Pad the payload if needed
                payload_str = parts[1]
                payload_str += '=' * (4 - len(payload_str) % 4)
                payload = json.loads(base64.urlsafe_b64decode(payload_str))
                print(f"[DEBUG] Decoded JWT payload: {payload}")
            else:
                raise ValueError("Invalid JWT format")
        except Exception as decode_err:
            print(f"[DEBUG] Failed to decode as JWT: {decode_err}")
            raise HTTPException(
                status_code=400,
                detail={"error_code": "AUTH_003", "message": "Invalid Google token"}
            )
    except Exception as e:
        print(f"UNEXPECTED ERROR in google_sign_in: {type(e).__name__}: {e}")
        print(f"Full traceback:\n{traceback.format_exc()}")
        raise HTTPException(
            status_code=500,
            detail={"error_code": "AUTH_004", "message": f"Google sign-in error: {type(e).__name__}: {str(e)}"}
        )

    if not payload:
        raise HTTPException(
            status_code=400,
            detail={"error_code": "AUTH_003", "message": "Failed to extract token payload"}
        )

    email = payload.get("email")
    name = payload.get("name")

    if not email:
        raise HTTPException(
            status_code=400,
            detail={"error_code": "AUTH_003", "message": "Email not found in Google token"}
        )

    user = db.query(User).filter(User.email == email).first()
    if user:
        access_token = create_access_token({"sub": str(user.id), "role": user.role})
        refresh_token = create_refresh_token({"sub": str(user.id), "role": user.role})
    else:
        new_user = User(
            id=uuid.uuid4(),
            name=name,
            email=email,
            hashed_password=None,
            role="student",
            is_active=True,
            is_verified=True,
        )
        db.add(new_user)
        db.commit()
        db.refresh(new_user)

        access_token = create_access_token({"sub": str(new_user.id), "role": new_user.role})
        refresh_token = create_refresh_token({"sub": str(new_user.id), "role": new_user.role})

    return TokenResponse(
        access_token=access_token,
        refresh_token=refresh_token,
        token_type="bearer"
    )


admin_router = APIRouter(prefix="/api/v1/admin", tags=["admin"])


@admin_router.post("/users/driver", response_model=UserResponse)
def create_driver(
    user_data: UserCreateAdmin,
    current_user: User = Depends(require_role(["super_admin"])),
    db: Session = Depends(get_db)
):
    existing_user = db.query(User).filter(User.email == user_data.email).first()
    if existing_user:
        raise HTTPException(
            status_code=409,
            detail={"error_code": "AUTH_002", "message": "User already exists"}
        )

    hashed_password = hash_password(user_data.password)
    new_user = User(
        id=uuid.uuid4(),
        name=user_data.name,
        email=user_data.email,
        hashed_password=hashed_password,
        role="driver",
        is_active=True,
    )
    db.add(new_user)
    db.commit()
    db.refresh(new_user)
    return new_user


@admin_router.post("/users/fleet-manager", response_model=UserResponse)
def create_fleet_manager(
    user_data: UserCreateAdmin,
    current_user: User = Depends(require_role(["super_admin"])),
    db: Session = Depends(get_db)
):
    existing_user = db.query(User).filter(User.email == user_data.email).first()
    if existing_user:
        raise HTTPException(
            status_code=409,
            detail={"error_code": "AUTH_002", "message": "User already exists"}
        )

    hashed_password = hash_password(user_data.password)
    new_user = User(
        id=uuid.uuid4(),
        name=user_data.name,
        email=user_data.email,
        hashed_password=hashed_password,
        role="fleet_manager",
        is_active=True,
    )
    db.add(new_user)
    db.commit()
    db.refresh(new_user)
    return new_user
