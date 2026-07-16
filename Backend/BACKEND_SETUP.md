# Backend Setup Guide for Frontend Team

## Prerequisites

- **Python 3.9+** installed
- **PostgreSQL 12+** with PostGIS extension
- **Git** installed

## Quick Start (5-10 minutes)

### 1. Install Python Dependencies

```bash
cd Backend
python -m venv venv

# On Windows:
venv\Scripts\activate

# On macOS/Linux:
source venv/bin/activate

pip install -r requirements.txt
```

### 2. Set Up Environment Variables

Create a `.env` file in the `Backend/` directory:

```env
# Database
DATABASE_URL=postgresql://postgres:password@localhost:5432/campride
SQLALCHEMY_DATABASE_URL=postgresql://postgres:password@localhost:5432/campride

# Google OAuth (optional for testing - test account doesn't require)
GOOGLE_OAUTH_CLIENT_ID=your_google_client_id.apps.googleusercontent.com

# JWT
SECRET_KEY=your-super-secret-key-change-this-in-production
ALGORITHM=HS256

# Email (optional)
SMTP_SERVER=smtp.gmail.com
SMTP_PORT=587
SENDER_EMAIL=your-email@gmail.com
SENDER_PASSWORD=your-app-password
```

### 3. Create PostgreSQL Database

```bash
# Connect to PostgreSQL
psql -U postgres

# Create database
CREATE DATABASE campride;

# Enable PostGIS extension
\c campride
CREATE EXTENSION postgis;

# Exit
\q
```

### 4. Run Database Migrations

```bash
cd Backend
alembic upgrade head
```

### 5. Create Test Accounts

```bash
python create_test_accounts.py
```

This creates 4 test accounts:
- **student@test.com** (password: password123)
- **driver@test.com** (password: password123)
- **fleet@test.com** (password: password123)
- **admin@test.com** (password: password123)

### 6. Start the Backend Server

```bash
# From Backend/ directory
python -m uvicorn app.main:app --reload --port 8000
```

Backend will be available at: **http://localhost:8000**

Check health: http://localhost:8000/health

---

## API Overview (Phase 4 Endpoints)

### Authentication
- `POST /api/v1/auth/register` — Register new user (defaults to student role)
- `POST /api/v1/auth/login` — Email/password login
- `POST /api/v1/auth/google` — Google Sign-In
- `POST /api/v1/auth/verify-email` — Verify email with code
- `POST /api/v1/auth/refresh` — Refresh JWT token

### Driver Endpoints
- `GET /api/v1/driver/route` — Get driver's current assigned route
- `PUT /api/v1/driver/route` — Update/select driver's route
- `GET /api/v1/routes/{route_id}/stops` — Get stops for a route

### Fleet Manager Endpoints
- `GET /api/v1/fleet/drivers` — List all drivers
- `GET /api/v1/fleet/drivers/{driver_id}` — Get single driver details
- `GET /api/v1/fleet/shuttles` — List all shuttles

### Admin Endpoints (super_admin role only)
- **Shuttles**: `POST/GET/PUT/DELETE /api/v1/admin/shuttles`
- **Routes**: `POST/GET/PUT/DELETE /api/v1/admin/routes`
- **Stops**: `POST /api/v1/admin/routes/{route_id}/stops`, `DELETE /api/v1/admin/stops/{stop_id}`
- **Driver Management**: `POST /api/v1/admin/users/driver`, `POST /api/v1/admin/users/fleet-manager`

### Student/Public Endpoints
- `GET /api/v1/shuttles` — List all shuttles (public/student view)
- `GET /api/v1/routes/{route_id}` — Get route details
- `GET /api/v1/routes/{route_id}/stops` — Get route stops

---

## Frontend Configuration

The Frontend expects the backend at: **http://127.0.0.1:8000/api/v1**

If you change the backend URL or port, update this in:
```
Frontend/campride/lib/services/auth_api_service.dart
Frontend/campride/lib/services/shuttle_service.dart
```

Change:
```dart
const String baseUrl = 'http://127.0.0.1:8000/api/v1';
```

---

## Project Structure

```
Backend/
├── app/
│   ├── main.py              # FastAPI app setup
│   ├── database.py          # Database connection
│   ├── models/              # SQLAlchemy ORM models
│   │   ├── user.py
│   │   ├── shuttle.py
│   │   ├── route.py
│   │   ├── stop.py
│   │   └── ...
│   ├── schemas/             # Pydantic schemas (request/response)
│   ├── api/v1/              # API routes
│   │   ├── auth.py
│   │   ├── driver.py
│   │   ├── fleet.py
│   │   ├── shuttles.py
│   │   ├── routes.py
│   │   └── deps.py          # Dependency injection (auth, db)
│   └── core/
│       ├── security.py      # JWT, password hashing
│       ├── config.py        # Settings
│       └── email.py         # Email utilities
├── migrations/              # Alembic database migrations
├── create_test_accounts.py  # Script to create test users
└── requirements.txt         # Python dependencies
```

---

## Known Phase 4 Gaps / TODOs

1. **No Public Route List Endpoint**
   - Drivers need to select a route via `PUT /api/v1/driver/route`, but there's no public endpoint to list available routes
   - Workaround: Frontend currently uses `/api/v1/admin/routes` (requires super_admin role)
   - TODO: Create `GET /api/v1/routes` endpoint accessible to drivers/fleet managers

2. **Trip History Not Yet Implemented**
   - Phase 4 doesn't include trip history API
   - Frontend `trip_history_screen.dart` uses mock data with TODO comment for Phase 5
   - TODO: Implement trip tracking endpoints in Phase 5

3. **No Live Map / Real-Time Tracking**
   - Phase 5 feature - requires WebSockets or polling for location updates
   - Not included in Phase 4

4. **Shuttle Assignment to Drivers**
   - Admin can assign drivers to shuttles via `PUT /api/v1/admin/shuttles/{shuttle_id}/assign-driver`
   - But there's no endpoint to view a driver's assigned shuttle directly
   - Currently fetched via `/api/v1/fleet/drivers` which shows `assigned_shuttle`

---

## Troubleshooting

### PostgreSQL Connection Error
```
FATAL: database "campride" does not exist
```
→ Run the "Create PostgreSQL Database" step above

### PostGIS Extension Not Found
```
ERROR: extension "postgis" does not exist
```
→ Ensure PostGIS is installed on your PostgreSQL server
→ On Windows: Use pgAdmin or reinstall PostgreSQL with PostGIS option

### Port 8000 Already in Use
```bash
# Find process using port 8000
lsof -i :8000  # macOS/Linux
netstat -ano | findstr :8000  # Windows

# Kill process
kill -9 <PID>  # macOS/Linux
taskkill /PID <PID> /F  # Windows
```

### Database Migrations Failed
```bash
# Check current migration state
alembic current

# Downgrade and upgrade
alembic downgrade base
alembic upgrade head
```

---

## Testing the Backend

### Using cURL

```bash
# Create a user
curl -X POST http://localhost:8000/api/v1/auth/register \
  -H "Content-Type: application/json" \
  -d '{"name":"John","email":"john@test.com","password":"pass123"}'

# Login
curl -X POST http://localhost:8000/api/v1/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"driver@test.com","password":"password123"}'

# Get current user (requires Authorization header)
curl -X GET http://localhost:8000/api/v1/auth/me \
  -H "Authorization: Bearer <access_token_from_login>"
```

### Using Postman or Insomnia
- Import the API endpoints from the `/api/v1/` path
- Add `Authorization: Bearer <token>` header for authenticated endpoints

---

## Frontend & Backend Communication Flow

1. **Frontend** runs on `http://localhost:5002` (Flutter web)
2. **Backend** runs on `http://localhost:8000`
3. Frontend makes API calls to `http://localhost:8000/api/v1/*`
4. Backend validates JWT tokens from login/register responses
5. Backend returns JSON with role-based data filtering

### Example Login Flow
```
Frontend: POST /auth/login {email, password}
         ↓
Backend: Validates credentials, generates JWT
         ↓
Frontend: Stores JWT, decodes to get user.role
         ↓
Frontend: Routes to dashboard based on role
         ↓
Frontend: Uses JWT in Authorization header for all subsequent requests
```

---

## Important Notes for Frontend Team

- **CORS is enabled** for all origins (`allow_origins=["*"]`) in development
- **Database is transactional** — changes are committed immediately
- **Test data persists** — each run of `create_test_accounts.py` checks if users exist before creating
- **No rate limiting** — added in Phase 5+
- **All timestamps are UTC** — stored without timezone info
- **PostGIS geometry** — converted to lat/lng in API responses via `RouteResponse.from_orm_with_geometry()`

---

## Quick Reference: Test Account Credentials

| Email | Password | Role |
|-------|----------|------|
| student@test.com | password123 | student |
| driver@test.com | password123 | driver |
| fleet@test.com | password123 | fleet_manager |
| admin@test.com | password123 | super_admin |

---

## Next Steps (Phase 5)

- Live location tracking for shuttles
- Trip history and analytics
- Real-time notifications
- Request/booking system for students
- Advanced route optimization

---

**Questions?** Check `Backend/app/` for source code or the API endpoint files for implementation details.
