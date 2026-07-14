import asyncio
import os
from dotenv import load_dotenv
from sqlalchemy.ext.asyncio import create_async_engine

load_dotenv()

async def test_connection():
    DATABASE_URL = os.getenv("DATABASE_URL")
    if DATABASE_URL and not DATABASE_URL.startswith("postgresql+asyncpg"):
        DATABASE_URL = DATABASE_URL.replace("postgresql://", "postgresql+asyncpg://")

    print(f"Testing connection to: {DATABASE_URL}")

    try:
        engine = create_async_engine(DATABASE_URL, echo=True)
        async with engine.begin() as conn:
            result = await conn.execute("SELECT 1")
            print("[OK] Connection successful!")
            return True
    except Exception as e:
        print(f"[ERROR] Connection failed: {e}")
        return False

if __name__ == "__main__":
    success = asyncio.run(test_connection())
    exit(0 if success else 1)
