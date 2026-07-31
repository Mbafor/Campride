# Part 1 Test Plan: Real Routes/Stops in Shuttle Matching UI

## Status
✅ Backend code: NEW GET /api/v1/routes endpoint added (Backend/app/api/v1/routes.py lines 48-55)
✅ Frontend code: Shuttle matching screen updated to fetch real routes/stops (Frontend/campride/lib/screens/student/shuttle_matching/shuttle_matching_screen.dart)

## What Changed
1. **Backend**: Added public endpoint `GET /api/v1/routes` that returns all available routes for authenticated students
2. **Frontend**: 
   - Removed hardcoded 12-stop mock list with wrong coordinates (5.75, -0.1667)
   - Added `_StopData` class to hold real stop data with route context
   - Added `_loadRoutesAndStops()` method to fetch routes from backend on app startup
   - Updated dropdown to show "Stop Name (RouteName)" format for clarity
   - Updated matching logic to use real coordinates instead of mock data

## Prerequisites for Testing
1. Backend deployed with new GET /api/v1/routes endpoint
2. Phase6TestRoute must exist in database with at least 3 stops

## Test Steps (Execute in Order)

### Step 1: Verify Backend Deployment
```bash
# Get a valid student JWT token, then run:
curl -X GET "https://campride-production.up.railway.app/api/v1/routes" \
  -H "Authorization: Bearer <STUDENT_JWT_TOKEN>" \
  -H "Content-Type: application/json"

# Expected: HTTP 200 with list of routes including Phase6TestRoute
# Example response:
# [
#   {"id": "...", "name": "Phase6TestRoute", "start_name": "Start", "end_name": "End", ...},
#   ...
# ]
```

### Step 2: Verify Routes Have Stops
```bash
# After getting a route ID from Step 1, run:
curl -X GET "https://campride-production.up.railway.app/api/v1/routes/<ROUTE_ID>/stops" \
  -H "Authorization: Bearer <STUDENT_JWT_TOKEN>" \
  -H "Content-Type: application/json"

# Expected: HTTP 200 with list of stops sorted by order
# Example: [
#   {"id": "...", "name": "Stop 1", "lat": 5.6037, "lng": -0.1870, "order": 0},
#   {"id": "...", "name": "Stop 2", "lat": 5.6040, "lng": -0.1872, "order": 1},
#   {"id": "...", "name": "Stop 3", "lat": 5.6043, "lng": -0.1875, "order": 2},
#   ...
# ]
```

### Step 3: Open Flutter App and Verify UI
1. Log in as a student (or create test student account if needed)
2. Navigate to "Find" tab (Shuttle Matching screen)
3. **Observe**: The pickup/destination dropdowns show "Stop N - Stop Name (Phase6TestRoute)" format
4. **Observe**: No hardcoded mock stops from 5.75/-0.1667 area (those should be gone)

### Step 4: Start Driver Telemetry for Phase6TestRoute
1. In a separate terminal, run the driver telemetry script:
```python
# Backend/tests/phase8_telemetry_test.py (or similar existing script)
# Set driver route to Phase6TestRoute
# Connect WebSocket to wss://campride-production.up.railway.app/api/v1/ws/driver/telemetry?token=<DRIVER_JWT>
# Send telemetry: {"lat": 5.6037, "lng": -0.1870, "heading": 90}
# Trip should auto-create on first ping
```

### Step 5: Test Matching with Real Stops
1. In the Flutter app (Step 3), select real stops:
   - Pickup: "Stop 1 - Start Area (Phase6TestRoute)"
   - Destination: "Stop 3 - End Area (Phase6TestRoute)"
2. Tap "Find Available Shuttles"
3. **Expected Result**: Should match Demo Shuttle B (or similar active shuttle assigned to Phase6TestRoute)
4. **Evidence**: Screenshot or description showing:
   - Real stops populated in dropdown (not mock coordinates)
   - Matching results showing available shuttles
   - Trip ID confirming driver connection

### Step 6: Verify Board Action
1. In Flutter UI, tap "I Boarded This Shuttle"
2. **Expected**: Success message and RideHistory created with boarded_at timestamp

## Success Criteria
- ✅ Real routes/stops displayed in dropdown (not hardcoded mock list)
- ✅ Dropdown labels show "Stop N - Name (RouteName)" format
- ✅ Matching returns results when selecting real Phase6TestRoute stops
- ✅ Boarding succeeds and creates RideHistory

## If Tests Fail

### 404 on GET /api/v1/routes
- Backend hasn't deployed yet
- Check Railway dashboard for active deployment
- May need to manually trigger build: `git push origin main` again

### Empty stops list in dropdown
- Routes fetched but stops endpoint returned empty
- Verify Phase6TestRoute has stops: Check database or admin panel
- Verify stops have correct coordinates that match driver telemetry

### No matching results despite driver telemetry
- Driver may not be on correct route
- Check: GET /api/v1/driver/route returns Phase6TestRoute ID
- Check: Driver telemetry coordinates within 300m of route stops
- Check: Trip was created (should see "ACTIVE TRIP FOUND" in logs)

## Timeline
After successful Part 1 testing, proceed to Part 2: Build "Change Route" functionality
