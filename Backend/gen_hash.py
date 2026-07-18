from passlib.context import CryptContext
pwd_context = CryptContext(schemes=["argon2"], deprecated="auto")
hashed = pwd_context.hash("password123")
print(f"Hashed password: {hashed}")
print(f"\nUse this SQL INSERT:\n")
print(f"INSERT INTO \"user\" (id, name, email, hashed_password, role, is_active, is_verified, created_at)")
print(f"VALUES (gen_random_uuid(), 'Test Super Admin', 'admin@test.com', '{hashed}', 'super_admin', true, true, NOW());")
