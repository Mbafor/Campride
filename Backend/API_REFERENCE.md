# CampRide API Reference

**Last Updated:** 2026-08-03

---

## Table of Contents

1. [Base URLs & Authentication](#base-urls--authentication)
2. [Authentication](#authentication)
3. [Shuttles & Matching](#shuttles--matching)
4. [Routes & Stops](#routes--stops)
5. [Driver Management](#driver-management)
6. [Student Ride History](#student-ride-history)
7. [Notifications](#notifications)
8. [Shuttle Requests](#shuttle-requests)
9. [Fleet Management](#fleet-management)
10. [Users & Account](#users--account)
11. [WebSocket Endpoints](#websocket-endpoints)
12. [Admin Endpoints](#admin-endpoints)

---

## Base URLs & Authentication

### Production URL
```
https://campride-production.up.railway.app/api/v1
```

### Authentication Methods

#### HTTP Endpoints
All authenticated HTTP requests must include the JWT token in the `Authorization` header:
```
Authorization: Bearer <access_token>
```

#### WebSocket Endpoints
JWT token is passed as a query parameter:
```
wss://campride-production.up.railway.app/api/v1/ws/<endpoint>?token=<jwt_token>
```

### Error Response Format
All error responses follow this standardized format:
```json
{
  "detail": {
    "error_code": "CATEGORY_NNN",
    "message": "Human-readable error message"
  }
}
```

---

## Authentication

### POST /auth/register
**Description:** Register a new student account

**Authentication:** None (public endpoint)

**Request Body:**
```json
{
  "name": "string",
  "email": "user@example.com",
  "password": "string (min 8 chars)",
  "role": "student"
}
```

**Response (200):**
```json
{
  "id": "uuid",
  "name": "string",
  "email": "string",
  "role": "student",
  "is_active": true,
  "is_verified": false,
  "created_at": "ISO8601",
  "email_sent": true,
  "email_error_message": null
}
```

**Error Codes:**
- `AUTH_002`: User already exists (409)

---

### POST /auth/verify-email
**Description:** Verify email with verification code sent during registration

**Authentication:** None (public endpoint)

**Request Body:**
```json
{
  "email": "user@example.com",
  "code": "string (6-digit code)"
}
```

**Response (200):**
```json
{
  "message": "Email verified successfully"
}
```

**Error Codes:**
- `AUTH_005`: User not found (404)
- `AUTH_006`: Invalid or expired verification code (400)

---

### POST /auth/resend-verification
**Description:** Resend verification code to email

**Authentication:** None (public endpoint)

**Request Body:**
```json
{
  "email": "user@example.com"
}
```

**Response (200):**
```json
{
  "message": "Verification code sent",
  "email_sent": true
}
```

**Error Codes:**
- `AUTH_005`: User not found (404)

---

### POST /auth/login
**Description:** Authenticate user and get access/refresh tokens

**Authentication:** None (public endpoint)

**Request Body:**
```json
{
  "email": "user@example.com",
  "password": "string"
}
```

**Response (200):**
```json
{
  "access_token": "string (JWT)",
  "refresh_token": "string (JWT)",
  "token_type": "bearer"
}
```

**Error Codes:**
- `AUTH_001`: Invalid credentials (401)
- `AUTH_007`: Email not verified (403)

---

### POST /auth/refresh
**Description:** Get new access token using refresh token

**Authentication:** None (public endpoint)

**Request Body:**
```json
{
  "refresh_token": "string"
}
```

**Response (200):**
```json
{
  "access_token": "string (JWT)",
  "refresh_token": "string (JWT)",
  "token_type": "bearer"
}
```

**Error Codes:**
- `AUTH_003`: Invalid token (401)
- `AUTH_005`: User not found (401)

---

### POST /auth/logout
**Description:** Log out user (clears session server-side)

**Authentication:** Any authenticated user

**Response (200):**
```json
{
  "message": "Logged out successfully"
}
```

---

### PUT /auth/change-password
**Description:** Change current user's password

**Authentication:** Any authenticated user

**Request Body:**
```json
{
  "current_password": "string",
  "new_password": "string (min 8 chars)"
}
```

**Response (200):**
```json
{
  "message": "Password changed successfully"
}
```

**Error Codes:**
- `AUTH_008`: Current password is incorrect (401)

---

### GET /auth/me
**Description:** Get current authenticated user's info

**Authentication:** Any authenticated user

**Response (200):**
```json
{
  "id": "uuid",
  "name": "string",
  "email": "string",
  "role": "student | driver | fleet_manager | super_admin",
  "is_active": true,
  "created_at": "ISO8601",
  "fcm_token": "string or null"
}
```

---

### POST /auth/google
**Description:** Sign in with Google (OAuth2)

**Authentication:** None (public endpoint)

**Request Body:**
```json
{
  "id_token": "string (Google ID token from client)"
}
```

**Response (200):**
```json
{
  "access_token": "string (JWT)",
  "refresh_token": "string (JWT)",
  "token_type": "bearer"
}
```

**Error Codes:**
- `AUTH_003`: Invalid Google ID token (400)
- `AUTH_004`: Google sign-in error (500)

---

## Shuttles & Matching

### GET /shuttles
**Description:** List all active shuttles

**Authentication:** Any authenticated user

**Response (200):**
```json
[
  {
    "id": "uuid",
    "name": "string",
    "plate_number": "string",
    "capacity": "integer",
    "status": "active | idle | offline",
    "driver_id": "uuid or null",
    "created_at": "ISO8601"
  }
]
```

---

### POST /shuttles/match
**Description:** Find shuttles matching a pickup/destination pair (core matching endpoint for students)

**Authentication:** Any authenticated user (typically students)

**Request Body:**
```json
{
  "pickup_lat": 6.7041,
  "pickup_lng": -1.5637,
  "destination_lat": 6.7100,
  "destination_lng": -1.5600
}
```

**Response (200):**
```json
{
  "shuttle_request_id": "uuid",
  "matched": [
    {
      "shuttle_id": "uuid or null",
      "shuttle_name": "string",
      "plate_number": "string",
      "driver_id": "uuid (string)",
      "current_lat": 6.7041,
      "current_lng": -1.5637,
      "eta_minutes": 5,
      "distance_meters": 1500.0,
      "route_name": "string or null",
      "pickup_stop": "string or null",
      "destination_stop": "string or null"
    }
  ],
  "nearby": [
    {
      "shuttle_id": "uuid or null",
      "shuttle_name": "string",
      "plate_number": "string",
      "driver_id": "uuid (string)",
      "current_lat": 6.7041,
      "current_lng": -1.5637,
      "eta_minutes": 12,
      "distance_meters": 2500.0
    }
  ]
}
```

**Notes:**
- `matched` array contains shuttles within 300m that cover the pickup-to-destination route
- `nearby` array contains additional shuttles within 1km radius but not on the route
- `eta_minutes` is calculated based on route and current position
- Creates a `ShuttleRequest` record for the student

---

### POST /shuttles/match/debug
**Description:** Debug version of matching endpoint - returns detailed logs

**Authentication:** Any authenticated user

**Request Body:** (same as `/shuttles/match`)

**Response (200):**
```json
{
  "matched": [...],
  "nearby": [...],
  "debug_logs": "string (captured stdout from matching algorithm)"
}
```

---

## Routes & Stops

### GET /routes
**Description:** List all available routes (for students to browse)

**Authentication:** Any authenticated user

**Response (200):**
```json
[
  {
    "id": "uuid",
    "name": "string",
    "start_name": "string",
    "end_name": "string",
    "start_lat": 6.7041,
    "start_lng": -1.5637,
    "end_lat": 6.7100,
    "end_lng": -1.5600,
    "created_at": "ISO8601"
  }
]
```

---

### GET /routes/{route_id}
**Description:** Get a specific route by ID

**Authentication:** Any authenticated user

**Path Parameters:**
- `route_id` (UUID)

**Response (200):** (same structure as single route object above)

**Error Codes:**
- `ROUTE_001`: Route not found (404)

---

### GET /routes/{route_id}/stops
**Description:** Get all stops for a specific route, ordered by sequence

**Authentication:** Any authenticated user

**Path Parameters:**
- `route_id` (UUID)

**Response (200):**
```json
[
  {
    "id": "uuid",
    "route_id": "uuid",
    "name": "string",
    "lat": 6.7041,
    "lng": -1.5637,
    "order": 1
  }
]
```

**Error Codes:**
- `ROUTE_001`: Route not found (404)

---

## Driver Management

### GET /driver/route
**Description:** Get the driver's currently assigned/active route

**Authentication:** Driver only

**Response (200):**
```json
{
  "id": "uuid",
  "name": "string",
  "start_name": "string",
  "end_name": "string",
  "start_lat": 6.7041,
  "start_lng": -1.5637,
  "end_lat": 6.7100,
  "end_lng": -1.5600,
  "created_at": "ISO8601"
}
```

**Response (200 if no route assigned):**
```json
null
```

---

### PUT /driver/route
**Description:** Set/update driver's assigned route

**Authentication:** Driver only

**Request Body:**
```json
{
  "route_id": "uuid"
}
```

**Response (200):**
```json
{
  "message": "Route updated successfully",
  "route": {
    "id": "uuid",
    "name": "string",
    "start_name": "string",
    "end_name": "string",
    "start_lat": 6.7041,
    "start_lng": -1.5637,
    "end_lat": 6.7100,
    "end_lng": -1.5600,
    "created_at": "ISO8601"
  }
}
```

**Error Codes:**
- `DRIVER_001`: Route not found (404)

---

### GET /driver/shuttle
**Description:** Get driver's currently assigned shuttle

**Authentication:** Driver only

**Response (200):**
```json
{
  "id": "uuid",
  "name": "string",
  "plate_number": "string",
  "capacity": 30,
  "status": "active | idle | offline",
  "driver_id": "uuid",
  "created_at": "ISO8601"
}
```

**Error Codes:**
- No shuttle assigned (404)

---

### POST /driver/offline
**Description:** End driver's shift - removes from live tracking and closes active trip

**Authentication:** Driver only

**Response (200):**
```json
{
  "status": "success",
  "message": "Driver removed from live tracking and trip closed",
  "trip_id": "uuid (if trip was closed, null if none)",
  "trip_ended_at": "ISO8601 (if trip was closed)"
}
```

---

### GET /driver/trips
**Description:** Get driver's completed trips (paginated)

**Authentication:** Driver only

**Query Parameters:**
- `date` (optional): Filter by date in YYYY-MM-DD format. If omitted, returns all completed trips.

**Response (200):**
```json
{
  "count": 5,
  "trips": [
    {
      "trip_id": "uuid",
      "route_name": "Route 5",
      "shuttle_name": "Demo Shuttle A",
      "shuttle_plate": "ABC-123",
      "started_at": "ISO8601",
      "ended_at": "ISO8601",
      "duration_seconds": 1800
    }
  ]
}
```

---

### GET /driver/trips/summary
**Description:** Get trip summary for driver for a specific date

**Authentication:** Driver only

**Query Parameters:**
- `date` (optional): YYYY-MM-DD format. Defaults to today.

**Response (200):**
```json
{
  "date": "2026-08-03",
  "total_completed_trips": 3,
  "routes": [
    {
      "route_name": "Route 5",
      "count": 2
    }
  ]
}
```

---

## Student Ride History

### GET /students/me/rides
**Description:** Get current student's ride history (boarding records), most recent first

**Authentication:** Student (any authenticated user, typically)

**Response (200):**
```json
{
  "rides": [
    {
      "ride_id": "uuid",
      "route_name": "Route 5",
      "shuttle_name": "Demo Shuttle A",
      "shuttle_plate": "ABC-123",
      "boarded_at": "ISO8601 (or null if not boarded)",
      "alighted_at": "ISO8601 (or null if still riding)",
      "duration_seconds": 1800,
      "created_at": "ISO8601"
    }
  ],
  "total": 5
}
```

---

## Notifications

### GET /notifications
**Description:** Get all notifications for current user, most recent first

**Authentication:** Any authenticated user

**Response (200):**
```json
{
  "notifications": [
    {
      "id": "uuid",
      "type": "shuttle_arrived | shuttle_nearby | five_stops_away | shuttle_heading_your_way",
      "message": "string",
      "is_read": false,
      "created_at": "ISO8601",
      "trip_id": "uuid (or null)"
    }
  ]
}
```

---

### GET /notifications/unread-count
**Description:** Get count of unread notifications

**Authentication:** Any authenticated user

**Response (200):**
```json
{
  "unread_count": 3
}
```

---

### PUT /notifications/{notification_id}/read
**Description:** Mark a single notification as read

**Authentication:** Any authenticated user (can only mark own notifications)

**Path Parameters:**
- `notification_id` (UUID)

**Response (200):**
```json
{
  "id": "uuid",
  "type": "string",
  "message": "string",
  "is_read": true,
  "created_at": "ISO8601",
  "trip_id": "uuid (or null)"
}
```

**Error Codes:**
- `NOTIF_001`: Notification not found (404)
- `NOTIF_002`: Permission denied (403)

---

## Shuttle Requests

### GET /shuttle-requests
**Description:** List current user's (student's) shuttle requests, most recent first

**Authentication:** Any authenticated user (typically student)

**Response (200):**
```json
{
  "shuttle_requests": [
    {
      "id": "uuid",
      "status": "pending | matched | completed",
      "matched_trip_id": "uuid (or null)",
      "created_at": "ISO8601",
      "updated_at": "ISO8601 (or null)"
    }
  ]
}
```

---

### POST /shuttle-requests/{shuttle_request_id}/board
**Description:** Confirm boarding for a matched shuttle request (creates RideHistory record)

**Authentication:** Student (can only board own requests)

**Path Parameters:**
- `shuttle_request_id` (UUID)

**Response (200):**
```json
{
  "ride_id": "uuid",
  "boarded_at": "ISO8601",
  "trip_id": "uuid",
  "message": "Successfully boarded shuttle"
}
```

**Error Codes:**
- `REQUEST_001`: Shuttle request not found (404)
- `REQUEST_002`: Permission denied (403)
- `REQUEST_003`: Cannot board - request status not "matched" (400)
- `REQUEST_004`: Shuttle request has no matched trip (400)

---

## Users & Account

### POST /users/fcm-token
**Description:** Register or update Firebase Cloud Messaging token for push notifications

**Authentication:** Any authenticated user

**Request Body:**
```json
{
  "fcm_token": "string"
}
```

**Response (200):**
```json
{
  "message": "FCM token updated successfully",
  "user_id": "uuid",
  "fcm_token_registered": true
}
```

---

### PUT /users/me
**Description:** Update current user's name

**Authentication:** Any authenticated user

**Request Body:**
```json
{
  "name": "string"
}
```

**Response (200):**
```json
{
  "id": "uuid",
  "name": "string",
  "email": "string",
  "role": "string",
  "is_active": true,
  "created_at": "ISO8601",
  "fcm_token": "string or null"
}
```

---

### GET /users/me
**Description:** Get current user's information

**Authentication:** Any authenticated user

**Response (200):**
```json
{
  "id": "uuid",
  "name": "string",
  "email": "string",
  "role": "student | driver | fleet_manager | super_admin",
  "is_active": true,
  "created_at": "ISO8601",
  "fcm_token": "string or null"
}
```

---

## WebSocket Endpoints

### WS /ws/driver/telemetry
**Description:** Driver telemetry endpoint - drivers stream location, heading, and accuracy updates in real-time

**Authentication:** JWT token as query parameter: `?token=<jwt>`

**Required Conditions:**
- Driver must have an assigned shuttle
- Driver must have an assigned route
- Driver must have "driver" role

**Connection Lifecycle:**
1. On successful connection, server responds with:
   ```json
   {
     "status": "connected",
     "message": "Telemetry connection established"
   }
   ```
   Automatically creates or finds active Trip record for this driver.

2. Driver sends location updates (continuously while driving):
   ```json
   {
     "lat": 6.7041,
     "lng": -1.5637,
     "heading": 45.5,
     "accuracy": 5.0,
     "timestamp": "2026-08-03T10:30:00Z"
   }
   ```

3. Server responds to each update:
   ```json
   {
     "status": "accepted | rejected | filtered | error",
     "message": "Location update recorded",
     "lat": 6.7041,
     "lng": -1.5637
   }
   ```

**Filters Applied:**
- Distance filter: Updates within 2m of last position are filtered
- Coordinate validation: Null Island (0,0), latitude/longitude range checks
- Accuracy validation: Non-negative number
- Timestamp validation: Not more than 30 seconds in future

**Disconnect Behavior:**
- Keeps driver in Redis live tracking
- Keeps trip active
- Use explicit `/driver/offline` endpoint to close trip and remove from tracking

**Error Codes (WebSocket Close Codes):**
- `1008`: Invalid JWT token
- `1008`: No shuttle assigned
- `1008`: No route assigned

---

### WS /ws/live-map
**Description:** Student/viewer live map endpoint - broadcasts real-time shuttle positions to all connected clients

**Authentication:** JWT token as query parameter: `?token=<jwt>`

**Connection Lifecycle:**
1. On connection, server immediately sends initial snapshot of all active drivers:
   ```json
   {
     "type": "initial_snapshot",
     "data": {
       "driver_id_1": {
         "driver_id": "uuid",
         "lat": 6.7041,
         "lng": -1.5637,
         "heading": 45.5,
         "accuracy": 5.0,
         "last_updated": "ISO8601"
       }
     }
   }
   ```

2. Then continuously broadcasts driver location updates:
   ```json
   {
     "type": "driver_location_update",
     "data": {
       "driver_id": "uuid",
       "lat": 6.7041,
       "lng": -1.5637,
       "heading": 45.5,
       "accuracy": 5.0,
       "last_updated": "ISO8601"
     }
   }
   ```

**Broadcast Mechanism:**
- Updates come from Redis pub/sub channel `driver-location-updates`
- Updates are published by the telemetry WebSocket endpoint
- All connected live-map clients receive updates in real-time

**Notification Triggers:**
- Server automatically triggers push notifications to matched students based on shuttle proximity:
  - `shuttle_heading_your_way`: When shuttle begins route toward pickup
  - `five_stops_away`: When shuttle is 5+ stops away from pickup
  - `shuttle_nearby`: When shuttle is within 500m
  - `shuttle_arrived`: When shuttle is within 50m (at pickup)

---

## Admin Endpoints

### POST /admin/users/driver
**Description:** Create a new driver account (admin only)

**Authentication:** super_admin or fleet_manager

**Request Body:**
```json
{
  "name": "string",
  "email": "string",
  "password": "string (min 8 chars)",
  "role": "driver"
}
```

**Response (200):**
```json
{
  "id": "uuid",
  "name": "string",
  "email": "string",
  "role": "driver",
  "is_active": true,
  "created_at": "ISO8601",
  "fcm_token": null
}
```

**Error Codes:**
- `AUTH_002`: User already exists (409)

---

### POST /admin/users/fleet-manager
**Description:** Create a new fleet manager account (super_admin only)

**Authentication:** super_admin

**Request Body:**
```json
{
  "name": "string",
  "email": "string",
  "password": "string (min 8 chars)",
  "role": "fleet_manager"
}
```

**Response (200):** (same as driver creation)

**Error Codes:**
- `AUTH_002`: User already exists (409)

---

### GET /admin/stats
**Description:** Get system-wide statistics (super_admin only)

**Authentication:** super_admin

**Response (200):**
```json
{
  "users_by_role": {
    "student": 50,
    "driver": 10,
    "fleet_manager": 2,
    "super_admin": 1
  },
  "total_shuttles": 8,
  "total_routes": 5
}
```

---

### POST /admin/shuttles
**Description:** Create a new shuttle

**Authentication:** super_admin or fleet_manager

**Request Body:**
```json
{
  "name": "Demo Shuttle A",
  "plate_number": "ABC-123",
  "capacity": 30
}
```

**Response (200):**
```json
{
  "id": "uuid",
  "name": "string",
  "plate_number": "string",
  "capacity": 30,
  "status": "idle",
  "driver_id": null,
  "created_at": "ISO8601"
}
```

**Error Codes:**
- `SHUTTLE_001`: Shuttle with this plate number already exists (409)

---

### GET /admin/shuttles
**Description:** List all shuttles (super_admin only)

**Authentication:** super_admin

**Response (200):** (array of shuttle objects, same structure as create response)

---

### GET /admin/shuttles/{shuttle_id}
**Description:** Get specific shuttle details (super_admin only)

**Authentication:** super_admin

**Path Parameters:**
- `shuttle_id` (UUID)

**Response (200):** (shuttle object)

**Error Codes:**
- `SHUTTLE_002`: Shuttle not found (404)

---

### PUT /admin/shuttles/{shuttle_id}
**Description:** Update shuttle details

**Authentication:** super_admin or fleet_manager

**Path Parameters:**
- `shuttle_id` (UUID)

**Request Body:**
```json
{
  "name": "string (optional)",
  "plate_number": "string (optional)",
  "capacity": 30,
  "status": "active | idle | offline (optional)",
  "driver_id": "uuid (optional)"
}
```

**Response (200):** (updated shuttle object)

**Error Codes:**
- `SHUTTLE_002`: Shuttle not found (404)

---

### DELETE /admin/shuttles/{shuttle_id}
**Description:** Delete a shuttle

**Authentication:** super_admin or fleet_manager

**Path Parameters:**
- `shuttle_id` (UUID)

**Response (200):**
```json
{
  "message": "Shuttle deleted successfully"
}
```

**Error Codes:**
- `SHUTTLE_002`: Shuttle not found (404)

---

### PUT /admin/shuttles/{shuttle_id}/assign-driver
**Description:** Assign a driver to a shuttle

**Authentication:** super_admin or fleet_manager

**Path Parameters:**
- `shuttle_id` (UUID)

**Request Body:**
```json
{
  "driver_id": "uuid"
}
```

**Response (200):**
```json
{
  "message": "Driver assigned successfully",
  "shuttle": {
    "id": "uuid",
    "name": "string",
    "plate_number": "string",
    "capacity": 30,
    "status": "idle",
    "driver_id": "uuid",
    "created_at": "ISO8601"
  }
}
```

**Error Codes:**
- `SHUTTLE_002`: Shuttle not found (404)
- `SHUTTLE_003`: Driver not found or user is not a driver (404)

---

### POST /admin/routes
**Description:** Create a new route

**Authentication:** super_admin

**Request Body:**
```json
{
  "name": "Route 5",
  "start_name": "Campus Gate",
  "end_name": "Main Bus Station",
  "start_lat": 6.7041,
  "start_lng": -1.5637,
  "end_lat": 6.7100,
  "end_lng": -1.5600
}
```

**Response (200):**
```json
{
  "id": "uuid",
  "name": "string",
  "start_name": "string",
  "end_name": "string",
  "start_lat": 6.7041,
  "start_lng": -1.5637,
  "end_lat": 6.7100,
  "end_lng": -1.5600,
  "created_at": "ISO8601"
}
```

---

### GET /admin/routes
**Description:** List all routes (super_admin only)

**Authentication:** super_admin

**Response (200):** (array of route objects)

---

### PUT /admin/routes/{route_id}
**Description:** Update a route

**Authentication:** super_admin

**Path Parameters:**
- `route_id` (UUID)

**Request Body:** (same as create)

**Response (200):** (updated route object)

**Error Codes:**
- `ROUTE_001`: Route not found (404)

---

### DELETE /admin/routes/{route_id}
**Description:** Delete a route

**Authentication:** super_admin

**Path Parameters:**
- `route_id` (UUID)

**Response (200):**
```json
{
  "message": "Route deleted successfully"
}
```

**Error Codes:**
- `ROUTE_001`: Route not found (404)

---

### POST /admin/routes/{route_id}/stops
**Description:** Add a stop to a route

**Authentication:** super_admin

**Path Parameters:**
- `route_id` (UUID)

**Request Body:**
```json
{
  "name": "Stop Name",
  "lat": 6.7041,
  "lng": -1.5637,
  "order": 1
}
```

**Response (200):**
```json
{
  "id": "uuid",
  "route_id": "uuid",
  "name": "string",
  "lat": 6.7041,
  "lng": -1.5637,
  "order": 1
}
```

**Error Codes:**
- `ROUTE_001`: Route not found (404)

---

### DELETE /admin/stops/{stop_id}
**Description:** Delete a stop from a route

**Authentication:** super_admin

**Path Parameters:**
- `stop_id` (UUID)

**Response (200):**
```json
{
  "message": "Stop deleted successfully"
}
```

---

## Fleet Management

### GET /fleet/drivers
**Description:** List all drivers with assignments (fleet_manager or super_admin)

**Authentication:** fleet_manager or super_admin

**Response (200):**
```json
[
  {
    "id": "uuid",
    "name": "string",
    "email": "string",
    "is_active": true,
    "assigned_shuttle": {
      "id": "uuid",
      "name": "string",
      "plate_number": "string",
      "status": "active | idle | offline"
    },
    "assigned_route": {
      "id": "uuid",
      "name": "string"
    }
  }
]
```

---

### GET /fleet/drivers/{driver_id}
**Description:** Get specific driver details with assignments

**Authentication:** fleet_manager or super_admin

**Path Parameters:**
- `driver_id` (UUID)

**Response (200):**
```json
{
  "id": "uuid",
  "name": "string",
  "email": "string",
  "is_active": true,
  "created_at": "ISO8601",
  "assigned_shuttle": { ... },
  "assigned_route": { ... }
}
```

**Error Codes:**
- `FLEET_001`: Driver not found (404)

---

### GET /fleet/shuttles
**Description:** List all shuttles with driver assignments

**Authentication:** fleet_manager or super_admin

**Response (200):**
```json
[
  {
    "id": "uuid",
    "name": "string",
    "plate_number": "string",
    "capacity": 30,
    "status": "active | idle | offline",
    "assigned_driver": {
      "id": "uuid",
      "name": "string",
      "email": "string"
    }
  }
]
```

---

### GET /fleet/drivers/{driver_id}/rides
**Description:** Get rides for a specific driver with optional date filtering and pagination

**Authentication:** fleet_manager or super_admin

**Path Parameters:**
- `driver_id` (UUID)

**Query Parameters:**
- `date` (optional): Filter by date in YYYY-MM-DD format
- `limit` (optional): Number of rides per page (default 20, max 100)
- `offset` (optional): Pagination offset (default 0)

**Response (200):**
```json
{
  "driver_id": "uuid",
  "driver_name": "string",
  "date": "YYYY-MM-DD (or null if no date filter)",
  "pagination": {
    "limit": 20,
    "offset": 0,
    "total_count": 45,
    "returned_count": 20
  },
  "rides": [
    {
      "ride_id": "uuid",
      "route_name": "string",
      "shuttle_name": "string",
      "shuttle_plate": "string",
      "boarded_at": "ISO8601 (trip start)",
      "alighted_at": "ISO8601 (trip end)",
      "duration_seconds": 1800
    }
  ]
}
```

**Error Codes:**
- `FLEET_001`: Driver not found (404)

---

### GET /fleet/drivers/{driver_id}/routes
**Description:** Get all distinct routes a driver has taken historically

**Authentication:** fleet_manager or super_admin

**Path Parameters:**
- `driver_id` (UUID)

**Response (200):**
```json
{
  "driver_id": "uuid",
  "driver_name": "string",
  "total_distinct_routes": 3,
  "routes": [
    {
      "route_name": "Route 5",
      "trip_count": 12,
      "last_used": "ISO8601"
    }
  ]
}
```

**Error Codes:**
- `FLEET_001`: Driver not found (404)

---

### GET /fleet/shuttles/active
**Description:** Get all shuttles with drivers currently transmitting telemetry (real-time location data from Redis)

**Authentication:** fleet_manager or super_admin

**Response (200):**
```json
{
  "total_active": 3,
  "shuttles": [
    {
      "shuttle_id": "uuid",
      "shuttle_name": "Demo Shuttle A",
      "shuttle_plate": "ABC-123",
      "capacity": 30,
      "driver_id": "uuid",
      "driver_name": "John Doe",
      "driver_email": "john@example.com",
      "current_lat": 6.7041,
      "current_lng": -1.5637,
      "heading": 45.5,
      "accuracy": 5.0,
      "last_updated": "ISO8601",
      "current_route": "Route 5"
    }
  ]
}
```

---

## Diagnostic Endpoints

### GET /auth/diagnostic/firebase
**Description:** Check Firebase Admin SDK initialization status (testing only)

**Authentication:** None (public endpoint)

**Response (200):**
```json
{
  "status": "initialized | error",
  "firebase_ready": true | false,
  "notifications_available": true | false,
  "error": "string (if status is error)"
}
```

---

## Implementation Notes for Frontend

### Shuttle Matching Response Structure
The `/shuttles/match` endpoint returns matches in a **nested "matched" array**, not as a flat list:
```json
{
  "matched": [
    {
      "shuttle_id": "...",
      "eta_minutes": 5,
      ...
    }
  ]
}
```

**This is NOT:**
```json
{
  "shuttle_id": "...",
  "eta_minutes": 5
}
```

Always extract the first matched result from the array if available.

### Coordinate System
- **Latitude (lat)**: North-South position (e.g., 6.7041)
- **Longitude (lng)**: East-West position (e.g., -1.5637)
- All coordinates use WGS84 (GPS) standard

### Timestamp Format
All timestamps are ISO8601 format (e.g., `2026-08-03T10:30:00Z`), handle both with and without timezone info.

### Error Handling
Always check `detail.error_code` and `detail.message` for error information. Do not rely on HTTP status codes alone.

### Rate Limiting
Not currently enforced, but assume 100 requests/second per IP as a reasonable limit.

### Token Refresh
Access tokens have a default expiration; use the refresh token endpoint to get new ones before expiration.
