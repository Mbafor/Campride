import os
from dotenv import load_dotenv
from pydantic_settings import BaseSettings

load_dotenv()


class Settings(BaseSettings):
    # Required environment variables (fail fast if missing)
    DATABASE_URL: str
    JWT_SECRET: str
    RESEND_API_KEY: str

    # Optional environment variables
    GOOGLE_OAUTH_CLIENT_ID: str = ""

    # Fixed configuration (not environment-dependent)
    JWT_ALGORITHM: str = "HS256"
    ACCESS_TOKEN_EXPIRE_MINUTES: int = 30
    REFRESH_TOKEN_EXPIRE_DAYS: int = 7

    class Config:
        env_file = ".env"
        case_sensitive = False
        extra = "ignore"


settings = Settings()
