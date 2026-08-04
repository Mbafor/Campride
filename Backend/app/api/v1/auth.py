from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from datetime import datetime
from pydantic import BaseModel
import uuid
import random
import string

from app.database import SessionLocal
from app.models import User, VerificationCode, Shuttle, Route
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


class RegisterResponse(BaseModel):
    id: str
    name: str
    email: str
    role: str
    is_active: bool
    is_verified: bool
    created_at: str
    email_sent: bool
    email_error_message: str | None = None


class EmailResendRequest(BaseModel):
    email: str


def generate_verification_code() -> str:
    return ''.join(random.choices(string.digits, k=6))


@router.post("/register", response_model=RegisterResponse)
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

    email_sent = send_verification_email(new_user.email, code)
    email_error = None
    if not email_sent:
        email_error = "Failed to send verification email. Check your email settings or use resend-verification if it doesn't arrive."

    return RegisterResponse(
        id=str(new_user.id),
        name=new_user.name,
        email=new_user.email,
        role=new_user.role,
        is_active=new_user.is_active,
        is_verified=new_user.is_verified,
        created_at=new_user.created_at.isoformat(),
        email_sent=email_sent,
        email_error_message=email_error
    )


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

    email_sent = send_verification_email(user.email, code)

    if email_sent:
        return {"message": "Verification code sent", "email_sent": True}
    else:
        return {"message": "Account created but email delivery failed. Check your email or try again shortly.", "email_sent": False, "error": "Email service unavailable"}


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

    if not user.is_active:
        raise HTTPException(
            status_code=403,
            detail={"error_code": "AUTH_009", "message": "This account has been deleted"}
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

    if not user.is_active:
        raise HTTPException(
            status_code=401,
            detail={"error_code": "AUTH_009", "message": "This account has been deleted"}
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


class ChangePasswordRequest(BaseModel):
    current_password: str
    new_password: str


@router.put("/change-password")
def change_password(
    request: ChangePasswordRequest,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """Change current user's password. Requires verification of current password."""
    if not verify_password(request.current_password, current_user.hashed_password):
        raise HTTPException(
            status_code=401,
            detail={"error_code": "AUTH_008", "message": "Current password is incorrect"}
        )

    hashed_new_password = hash_password(request.new_password)
    current_user.hashed_password = hashed_new_password
    db.commit()
    db.refresh(current_user)

    return {"message": "Password changed successfully"}


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

    try:
        # Verify ID token against Google's public keys
        # This is the ONLY accepted authentication method
        payload = id_token.verify_oauth2_token(
            request.id_token,
            requests.Request(),
            settings.GOOGLE_OAUTH_CLIENT_ID
        )
        print(f"[DEBUG] ID token verified successfully. Email: {payload.get('email')}")
    except ValueError as e:
        # ID token verification failed - reject the request
        print(f"[DEBUG] ID token verification failed: {e}")
        raise HTTPException(
            status_code=400,
            detail={"error_code": "AUTH_003", "message": "Invalid Google ID token"}
        )
    except Exception as e:
        # Any other error during verification - reject
        print(f"ERROR in google_sign_in: {type(e).__name__}: {e}")
        print(f"Full traceback:\n{traceback.format_exc()}")
        raise HTTPException(
            status_code=500,
            detail={"error_code": "AUTH_004", "message": f"Google sign-in error: {type(e).__name__}"}
        )

    # Extract verified claims from the ID token
    email = payload.get("email")
    name = payload.get("name")
    picture = payload.get("picture")

    if not email:
        raise HTTPException(
            status_code=400,
            detail={"error_code": "AUTH_003", "message": "Email not found in verified Google token"}
        )

    user = db.query(User).filter(User.email == email).first()
    if user:
        if not user.is_active:
            raise HTTPException(
                status_code=403,
                detail={"error_code": "AUTH_009", "message": "This account has been deleted"}
            )
        # Backfill the Google avatar for accounts that don't have a photo yet.
        if not user.photo_url and picture:
            user.photo_url = picture
            db.commit()
        access_token = create_access_token({"sub": str(user.id), "role": user.role})
        refresh_token = create_refresh_token({"sub": str(user.id), "role": user.role})
    else:
        try:
            new_user = User(
                id=uuid.uuid4(),
                name=name,
                email=email,
                hashed_password=None,
                role="student",
                is_active=True,
                is_verified=True,
                photo_url=picture,
            )
            db.add(new_user)
            db.commit()
            db.refresh(new_user)

            access_token = create_access_token({"sub": str(new_user.id), "role": new_user.role})
            refresh_token = create_refresh_token({"sub": str(new_user.id), "role": new_user.role})
        except Exception as e:
            db.rollback()
            user = db.query(User).filter(User.email == email).first()
            if user:
                access_token = create_access_token({"sub": str(user.id), "role": user.role})
                refresh_token = create_refresh_token({"sub": str(user.id), "role": user.role})
            else:
                raise HTTPException(
                    status_code=500,
                    detail={"error_code": "AUTH_004", "message": "Failed to create or find user"}
                )

    return TokenResponse(
        access_token=access_token,
        refresh_token=refresh_token,
        token_type="bearer"
    )


@router.get("/diagnostic/firebase")
def check_firebase_status():
    """Check if Firebase Admin SDK is initialized (for testing only)"""
    try:
        from app.core.notifications import _firebase_app, _initialize_firebase

        # Try to initialize if not already done
        _initialize_firebase()

        return {
            "status": "initialized",
            "firebase_ready": _firebase_app is not None,
            "notifications_available": True
        }
    except Exception as e:
        return {
            "status": "error",
            "firebase_ready": False,
            "notifications_available": False,
            "error": str(e)
        }


class UserCountByRole(BaseModel):
    student: int
    driver: int
    fleet_manager: int
    super_admin: int


class AdminStatsResponse(BaseModel):
    users_by_role: UserCountByRole
    total_shuttles: int
    total_routes: int


admin_router = APIRouter(prefix="/api/v1/admin", tags=["admin"])


@admin_router.post("/users/driver", response_model=UserResponse)
def create_driver(
    user_data: UserCreateAdmin,
    current_user: User = Depends(require_role(["super_admin", "fleet_manager"])),
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


@admin_router.get("/stats", response_model=AdminStatsResponse)
def get_admin_stats(
    current_user: User = Depends(require_role(["super_admin"])),
    db: Session = Depends(get_db)
):
    # Count users by role
    student_count = db.query(User).filter(User.role == "student").count()
    driver_count = db.query(User).filter(User.role == "driver").count()
    fleet_manager_count = db.query(User).filter(User.role == "fleet_manager").count()
    super_admin_count = db.query(User).filter(User.role == "super_admin").count()

    # Count shuttles and routes
    total_shuttles = db.query(Shuttle).count()
    total_routes = db.query(Route).count()

    return AdminStatsResponse(
        users_by_role=UserCountByRole(
            student=student_count,
            driver=driver_count,
            fleet_manager=fleet_manager_count,
            super_admin=super_admin_count
        ),
        total_shuttles=total_shuttles,
        total_routes=total_routes
    )
