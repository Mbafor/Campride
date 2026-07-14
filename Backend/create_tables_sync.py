import os
from dotenv import load_dotenv
from sqlalchemy import create_engine
from sqlalchemy.orm import declarative_base
import sys

sys.path.insert(0, os.path.dirname(__file__))

from app.database import Base
from app import models

load_dotenv()

def create_tables():
    DATABASE_URL = os.getenv("DATABASE_URL")
    # Convert async URL to sync
    if DATABASE_URL:
        DATABASE_URL = DATABASE_URL.replace("postgresql+asyncpg://", "postgresql://")

    print(f"Creating tables using: {DATABASE_URL}")

    try:
        engine = create_engine(DATABASE_URL, echo=True)
        Base.metadata.create_all(engine)
        print("[OK] All tables created successfully!")
        engine.dispose()
        return True
    except Exception as e:
        print(f"[ERROR] Failed to create tables: {e}")
        import traceback
        traceback.print_exc()
        return False

if __name__ == "__main__":
    success = create_tables()
    exit(0 if success else 1)
