#!/usr/bin/env python3
"""
Script to create test accounts for all roles.
Run this once to set up test users for development/testing.

Usage: cd Backend && python create_test_accounts.py
"""
import uuid
from datetime import datetime, timezone
import os
import sys

# Add Backend to path
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

from app.database import SessionLocal, Base, engine
from app.models import User, UserRole
from app.core.security import hash_password

# Create tables if they don't exist
Base.metadata.create_all(bind=engine)

db = SessionLocal()

try:
    # Test account credentials
    test_accounts = [
        {
            "email": "student@test.com",
            "name": "Test Student",
            "password": "password123",
            "role": UserRole.student
        },
        {
            "email": "driver@test.com",
            "name": "Test Driver",
            "password": "password123",
            "role": UserRole.driver
        },
        {
            "email": "fleet@test.com",
            "name": "Test Fleet Manager",
            "password": "password123",
            "role": UserRole.fleet_manager
        },
        {
            "email": "admin@test.com",
            "name": "Test Super Admin",
            "password": "password123",
            "role": UserRole.super_admin
        }
    ]

    now = datetime.now(timezone.utc).replace(tzinfo=None)

    for account in test_accounts:
        # Check if user already exists
        existing = db.query(User).filter(User.email == account["email"]).first()
        if existing:
            print(f"[OK] {account['email']} already exists (role: {existing.role})")
            continue

        # Create new user
        user = User(
            id=uuid.uuid4(),
            name=account["name"],
            email=account["email"],
            hashed_password=hash_password(account["password"]),
            role=account["role"],
            is_active=True,
            is_verified=True,  # Skip email verification for test accounts
            created_at=now,
            updated_at=now
        )
        db.add(user)
        print(f"[OK] Created {account['email']} ({account['role']})")

    db.commit()
    print("\n[SUCCESS] Test accounts created successfully!")
    print("\nTest credentials:")
    for account in test_accounts:
        print(f"  - {account['email']}: {account['password']} (role: {account['role']})")

except Exception as e:
    db.rollback()
    print(f"[ERROR] Error creating test accounts: {e}")
    import traceback
    traceback.print_exc()
finally:
    db.close()
