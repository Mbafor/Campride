from fastapi import Depends, HTTPException, Header
from app.database import SessionLocal
from app.models import User
from app.core.security import decode_token
from typing import Optional


def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()


def get_current_user(authorization: Optional[str] = Header(None), db=Depends(get_db)) -> User:
    if not authorization or not authorization.startswith("Bearer "):
        raise HTTPException(
            status_code=401,
            detail={"error_code": "AUTH_003", "message": "Invalid or missing token"}
        )

    token = authorization.replace("Bearer ", "", 1)
    try:
        payload = decode_token(token)
    except ValueError as e:
        raise HTTPException(
            status_code=401,
            detail={"error_code": "AUTH_003", "message": str(e)}
        )

    user_id = payload.get("sub")
    if not user_id:
        raise HTTPException(
            status_code=401,
            detail={"error_code": "AUTH_003", "message": "Invalid token"}
        )

    user = db.query(User).filter(User.id == user_id).first()
    if not user:
        raise HTTPException(
            status_code=401,
            detail={"error_code": "AUTH_005", "message": "User not found"}
        )

    return user


def require_role(allowed_roles: list):
    def role_checker(current_user: User = Depends(get_current_user)) -> User:
        if current_user.role not in allowed_roles:
            raise HTTPException(
                status_code=403,
                detail={"error_code": "AUTH_004", "message": "Insufficient permissions"}
            )
        return current_user
    return role_checker
