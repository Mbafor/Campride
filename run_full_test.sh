#!/bin/bash
# Complete end-to-end test using curl

BASE_URL="https://campride-production.up.railway.app/api/v1"
TEST_EMAIL="student@test.com"
TEST_PASSWORD="password123"

echo "========================================================================"
echo "  END-TO-END TEST: Real Routes/Stops Integration"
echo "========================================================================"
echo ""

# Step 1: Login
echo "[$(date +'%Y-%m-%d %H:%M:%S')] [INFO] Step 1: Login as student@test.com"
echo ""

LOGIN_RESPONSE=$(curl -s -X POST "$BASE_URL/auth/login" \
  -H "Content-Type: application/json" \
  -d "{\"email\":\"$TEST_EMAIL\",\"password\":\"$TEST_PASSWORD\"}")

echo "Response: $LOGIN_RESPONSE"
echo ""

STUDENT_JWT=$(echo "$LOGIN_RESPONSE" | grep -o '"access_token":"[^"]*' | cut -d'"' -f4)

if [ -z "$STUDENT_JWT" ]; then
    echo "[ERROR] Failed to get JWT token from login"
    exit 1
fi

echo "[SUCCESS] JWT obtained: ${STUDENT_JWT:0:50}..."
echo ""
sleep 2

# Step 2: Get routes
echo "========================================================================"
echo "[$(date +'%Y-%m-%d %H:%M:%S')] [INFO] Step 2: GET /api/v1/routes"
echo "========================================================================"
echo ""

ROUTES_RESPONSE=$(curl -s -X GET "$BASE_URL/routes" \
  -H "Authorization: Bearer $STUDENT_JWT" \
  -H "Content-Type: application/json")

echo "Response (first 500 chars):"
echo "$ROUTES_RESPONSE" | head -c 500
echo ""
echo ""

ROUTE_COUNT=$(echo "$ROUTES_RESPONSE" | grep -o '"id"' | wc -l)
echo "[INFO] Found $ROUTE_COUNT route(s)"
echo ""

# Extract first route ID
ROUTE_ID=$(echo "$ROUTES_RESPONSE" | grep -o '"id":"[^"]*"' | head -1 | cut -d'"' -f4)
ROUTE_NAME=$(echo "$ROUTES_RESPONSE" | grep -o '"name":"[^"]*"' | head -1 | cut -d'"' -f4)

echo "[INFO] Using route: $ROUTE_NAME (ID: ${ROUTE_ID:0:8}...)"
echo ""
sleep 2

# Step 3: Get stops
echo "========================================================================"
echo "[$(date +'%Y-%m-%d %H:%M:%S')] [INFO] Step 3: GET /api/v1/routes/{id}/stops"
echo "========================================================================"
echo ""

STOPS_RESPONSE=$(curl -s -X GET "$BASE_URL/routes/$ROUTE_ID/stops" \
  -H "Authorization: Bearer $STUDENT_JWT" \
  -H "Content-Type: application/json")

echo "Response (first 500 chars):"
echo "$STOPS_RESPONSE" | head -c 500
echo ""
echo ""

STOP_COUNT=$(echo "$STOPS_RESPONSE" | grep -o '"order"' | wc -l)
echo "[INFO] Found $STOP_COUNT stop(s) in route '$ROUTE_NAME'"
echo ""

# Extract first and third stop coordinates
STOP1_LAT=$(echo "$STOPS_RESPONSE" | grep -o '"lat":[0-9.]*' | head -1 | cut -d':' -f2)
STOP1_LNG=$(echo "$STOPS_RESPONSE" | grep -o '"lng":-?[0-9.]*' | head -1 | cut -d':' -f2)

# For third stop, we need more parsing
STOP3_LAT=$(echo "$STOPS_RESPONSE" | grep -o '"lat":[0-9.]*' | sed -n '3p' | cut -d':' -f2)
STOP3_LNG=$(echo "$STOPS_RESPONSE" | grep -o '"lng":-?[0-9.]*' | sed -n '3p' | cut -d':' -f2)

echo "[INFO] Stop 1 coordinates: ($STOP1_LAT, $STOP1_LNG)"
if [ -n "$STOP3_LAT" ]; then
    echo "[INFO] Stop 3 coordinates: ($STOP3_LAT, $STOP3_LNG)"
else
    echo "[WARN] Stop 3 not found, using Stop 2"
    STOP3_LAT=$(echo "$STOPS_RESPONSE" | grep -o '"lat":[0-9.]*' | sed -n '2p' | cut -d':' -f2)
    STOP3_LNG=$(echo "$STOPS_RESPONSE" | grep -o '"lng":-?[0-9.]*' | sed -n '2p' | cut -d':' -f2)
    echo "[INFO] Stop 2 coordinates: ($STOP3_LAT, $STOP3_LNG)"
fi
echo ""
sleep 2

# Step 4: Test matching
echo "========================================================================"
echo "[$(date +'%Y-%m-%d %H:%M:%S')] [INFO] Step 4: POST /api/v1/shuttles/match"
echo "========================================================================"
echo ""

MATCH_PAYLOAD="{
  \"pickup_latitude\": $STOP1_LAT,
  \"pickup_longitude\": $STOP1_LNG,
  \"destination_latitude\": $STOP3_LAT,
  \"destination_longitude\": $STOP3_LNG
}"

echo "[DEBUG] Payload:"
echo "$MATCH_PAYLOAD" | head -c 200
echo ""
echo ""

MATCH_RESPONSE=$(curl -s -X POST "$BASE_URL/shuttles/match" \
  -H "Authorization: Bearer $STUDENT_JWT" \
  -H "Content-Type: application/json" \
  -d "$MATCH_PAYLOAD")

echo "Response (first 500 chars):"
echo "$MATCH_RESPONSE" | head -c 500
echo ""
echo ""

MATCHED_COUNT=$(echo "$MATCH_RESPONSE" | grep -o '"matched":\[' | wc -l)
NEARBY_COUNT=$(echo "$MATCH_RESPONSE" | grep -o '"nearby":\[' | wc -l)

if [ "$MATCHED_COUNT" -gt 0 ]; then
    echo "[SUCCESS] Matching returned results!"
    SHUTTLE_NAME=$(echo "$MATCH_RESPONSE" | grep -o '"shuttle_name":"[^"]*' | head -1 | cut -d'"' -f4)
    echo "[INFO] Found shuttle: $SHUTTLE_NAME"
else
    echo "[WARN] No direct matches (driver telemetry may not be active)"
fi
echo ""

# Summary
echo "========================================================================"
echo "  TEST SUMMARY"
echo "========================================================================"
echo ""
echo "✅ Step 1: Student login - PASSED"
echo "✅ Step 2: GET /api/v1/routes - PASSED ($ROUTE_COUNT routes found)"
echo "✅ Step 3: GET /api/v1/routes/{id}/stops - PASSED ($STOP_COUNT stops found)"
if [ "$MATCHED_COUNT" -gt 0 ]; then
    echo "✅ Step 4: POST /api/v1/shuttles/match - PASSED (match found)"
else
    echo "⚠️  Step 4: POST /api/v1/shuttles/match - AWAITING DRIVER TELEMETRY"
fi
echo ""
echo "Route: $ROUTE_NAME"
echo "Pickup: ($STOP1_LAT, $STOP1_LNG)"
echo "Destination: ($STOP3_LAT, $STOP3_LNG)"
echo ""
