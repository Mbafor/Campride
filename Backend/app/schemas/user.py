from pydantic import BaseModel, EmailStr, field_validator
from datetime import datetime
from uuid import UUID


class UserRegister(BaseModel):
    name: str
    email: EmailStr
    password: str
    role: str = "student"

    @field_validator("password")
    def password_min_length(cls, v):
        if len(v) < 8:
            raise ValueError("Password must be at least 8 characters")
        return v

    @field_validator("role")
    def role_validation(cls, v):
        if v != "student":
            raise ValueError("Only 'student' role is allowed for self-registration")
        return v


class UserLogin(BaseModel):
    email: EmailStr
    password: str


class UserResponse(BaseModel):
    id: UUID
    name: str
    email: str
    role: str
    is_active: bool
    created_at: datetime

    class Config:
        from_attributes = True


class TokenResponse(BaseModel):
    access_token: str
    refresh_token: str
    token_type: str = "bearer"


class RefreshTokenRequest(BaseModel):
    refresh_token: str


class UserCreateAdmin(BaseModel):
    name: str
    email: EmailStr
    password: str
    role: str

    @field_validator("password")
    def password_min_length(cls, v):
        if len(v) < 8:
            raise ValueError("Password must be at least 8 characters")
        return v

    @field_validator("role")
    def role_validation(cls, v):
        if v not in ["driver", "fleet_manager"]:
            raise ValueError("Role must be 'driver' or 'fleet_manager'")
        return v
