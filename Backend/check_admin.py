#!/usr/bin/env python3
import os
import sys
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

from app.database import SessionLocal
from app.models import User
from app.core.security import hash_password
import uuid
from datetime import datetime, timezone

db = SessionLocal()

try:
    admin = db.query(User).filter(User.email == "admin@test.com").first()

    if admin:
        print(f"✅ FOUND: admin@test.com")
        print(f"   Role: {admin.role}")

        if admin.role == "super_admin":
            print(f"\n✅ CONFIRMED SUPER ADMIN")
            print(f"   Email: admin@test.com")
            print(f"   Password: password123")
            print(f"   Ready to test!")
    else:
        print("Creating admin@test.com as super_admin...")

        new_admin = User(
            id=uuid.uuid4(),
            name="Test Super Admin",
            email="admin@test.com",
            hashed_password=hash_password("password123"),
            role="super_admin",
            is_active=True,
            is_verified=True,
        )
        db.add(new_admin)
        db.commit()

        print("✅ CREATED SUPER ADMIN")
        print(f"   Email: admin@test.com")
        print(f"   Password: password123")
        print(f"   Ready to test!")

finally:
    db.close()
