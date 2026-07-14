import asyncio
import os
from dotenv import load_dotenv
from sqlalchemy.ext.asyncio import create_async_engine
from app.database import Base
from app.models import *

load_dotenv()

async def create_tables():
    DATABASE_URL = os.getenv("DATABASE_URL")
    if DATABASE_URL and not DATABASE_URL.startswith("postgresql+asyncpg"):
        DATABASE_URL = DATABASE_URL.replace("postgresql://", "postgresql+asyncpg://")

    print(f"Creating tables using: {DATABASE_URL}")

    try:
        engine = create_async_engine(
            DATABASE_URL,
            echo=True,
            future=True,
        )

        async with engine.begin() as conn:
            await conn.run_sync(Base.metadata.create_all)
            print("[OK] All tables created successfully!")

        await engine.dispose()
        return True
    except Exception as e:
        print(f"[ERROR] Failed to create tables: {e}")
        import traceback
        traceback.print_exc()
        return False

if __name__ == "__main__":
    success = asyncio.run(create_tables())
    exit(0 if success else 1)
