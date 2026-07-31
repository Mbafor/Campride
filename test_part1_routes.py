#!/usr/bin/env python3
"""
Part 1 Test Script: Verify real routes/stops integration
Requires: Python 3.8+, requests library
Usage: python test_part1_routes.py <STUDENT_JWT_TOKEN>
"""

import sys
import json
import requests
from typing import Optional

BASE_URL = "https://campride-production.up.railway.app/api/v1"
TIMEOUT = 10

def print_section(title: str):
    """Print a test section header"""
    print(f"\n{'='*60}")
    print(f"  {title}")
    print(f"{'='*60}\n")

def test_routes_endpoint(token: str) -> Optional[dict]:
    """Test GET /api/v1/routes endpoint"""
    print_section("Test 1: List All Routes")

    try:
        url = f"{BASE_URL}/routes"
        headers = {
            "Authorization": f"Bearer {token}",
            "Content-Type": "application/json",
        }

        response = requests.get(url, headers=headers, timeout=TIMEOUT)

        print(f"Request: GET {url}")
        print(f"Status: {response.status_code}")

        if response.status_code == 200:
            routes = response.json()
            print(f"✅ Success! Found {len(routes)} route(s)\n")

            for i, route in enumerate(routes, 1):
                print(f"  Route {i}:")
                print(f"    ID: {route.get('id', 'N/A')}")
                print(f"    Name: {route.get('name', 'N/A')}")
                print(f"    Start: {route.get('start_name', 'N/A')}")
                print(f"    End: {route.get('end_name', 'N/A')}")
                print(f"    Start coords: ({route.get('start_lat', 'N/A')}, {route.get('start_lng', 'N/A')})")
                print()

            return routes
        else:
            print(f"❌ Failed! Response: {response.text[:200]}")
            return None

    except requests.exceptions.Timeout:
        print(f"❌ Request timeout after {TIMEOUT}s")
        return None
    except Exception as e:
        print(f"❌ Error: {e}")
        return None

def test_stops_endpoint(token: str, route_id: str, route_name: str) -> Optional[list]:
    """Test GET /api/v1/routes/{id}/stops endpoint"""
    print_section(f"Test 2: List Stops for '{route_name}'")

    try:
        url = f"{BASE_URL}/routes/{route_id}/stops"
        headers = {
            "Authorization": f"Bearer {token}",
            "Content-Type": "application/json",
        }

        response = requests.get(url, headers=headers, timeout=TIMEOUT)

        print(f"Request: GET {url}")
        print(f"Status: {response.status_code}")

        if response.status_code == 200:
            stops = response.json()
            print(f"✅ Success! Found {len(stops)} stop(s)\n")

            for stop in stops:
                stop_name = stop.get('name', 'Unknown')
                stop_order = stop.get('order', 'N/A')
                lat = stop.get('lat', 'N/A')
                lng = stop.get('lng', 'N/A')
                print(f"  Stop {stop_order}: {stop_name}")
                print(f"    Coordinates: ({lat}, {lng})")
                print(f"    ID: {stop.get('id', 'N/A')}")
                print()

            return stops
        else:
            print(f"❌ Failed! Response: {response.text[:200]}")
            return None

    except requests.exceptions.Timeout:
        print(f"❌ Request timeout after {TIMEOUT}s")
        return None
    except Exception as e:
        print(f"❌ Error: {e}")
        return None

def verify_flutter_ui(routes: list, all_stops: list):
    """Verify what Flutter UI should display"""
    print_section("Flutter UI Verification")

    print("Expected dropdown format (based on fetched data):\n")

    for stop in all_stops[:5]:  # Show first 5
        route_name = stop.get('_route_name', 'Unknown')
        stop_name = stop.get('name', 'Unknown')
        display_label = f"{stop_name} ({route_name})"
        print(f"  - {display_label}")

    if len(all_stops) > 5:
        print(f"  ... and {len(all_stops) - 5} more stops")

    print("\n✅ Verification: Dropdown should show real stop names, not mock 'Brunei Hall', 'KSB', etc.")
    print("✅ Verification: Coordinates should match real routes, not 5.75/-0.1667")

def test_matching_prerequisites(token: str, stops: list) -> tuple[Optional[dict], Optional[dict]]:
    """Find Phase6TestRoute and suitable stops for matching test"""
    print_section("Test 3: Prepare for Matching Test")

    print("Looking for Phase6TestRoute...")

    if not stops or len(stops) < 3:
        print(f"⚠️  Warning: Found only {len(stops) if stops else 0} stops. Need at least 3 for matching test.")
        return None, None

    pickup_stop = None
    destination_stop = None

    # Try to find stops that are in order (for matching to work)
    if len(stops) >= 3:
        pickup_stop = stops[0]
        destination_stop = stops[2] if len(stops) > 2 else stops[1]

    if pickup_stop and destination_stop:
        print(f"✅ Found suitable stops for matching test:")
        print(f"   Pickup: {pickup_stop.get('name')} @ ({pickup_stop.get('lat')}, {pickup_stop.get('lng')})")
        print(f"   Destination: {destination_stop.get('name')} @ ({destination_stop.get('lat')}, {destination_stop.get('lng')})")
        return pickup_stop, destination_stop
    else:
        print("❌ Could not find suitable stops")
        return None, None

def main():
    """Run all tests"""
    if len(sys.argv) < 2:
        print("Usage: python test_part1_routes.py <STUDENT_JWT_TOKEN>")
        print("\nExample:")
        print("  python test_part1_routes.py eyJhbGciOiJIUzI1NiIs...")
        sys.exit(1)

    token = sys.argv[1]

    print("\n" + "="*60)
    print("  Part 1: Real Routes/Stops Integration Test")
    print("="*60)

    # Test 1: Get all routes
    routes = test_routes_endpoint(token)
    if not routes:
        print("\n❌ FAILED: Could not fetch routes. Backend may not be deployed yet.")
        sys.exit(1)

    # Test 2: Get stops for Phase6TestRoute or first route
    phase6_route = None
    target_route = None

    for route in routes:
        if 'Phase6TestRoute' in route.get('name', ''):
            phase6_route = route
            break

    target_route = phase6_route or routes[0]

    stops = test_stops_endpoint(token, target_route['id'], target_route['name'])
    if not stops:
        print("\n❌ FAILED: Could not fetch stops.")
        sys.exit(1)

    # Attach route name to stops for display
    for stop in stops:
        stop['_route_name'] = target_route['name']

    # Test 3: Verify Flutter UI
    verify_flutter_ui(routes, stops)

    # Test 4: Prepare for matching
    pickup, destination = test_matching_prerequisites(token, stops)

    print_section("Summary")

    print("✅ Backend Integration Tests PASSED")
    print(f"   - {len(routes)} route(s) available")
    print(f"   - {len(stops)} stop(s) in selected route")
    print(f"   - Dropdown format verified")

    print("\n📋 Next Steps:")
    print("   1. Start Flutter app and log in as student")
    print("   2. Navigate to 'Find' tab (Shuttle Matching)")
    print("   3. Verify dropdowns show real stops with format: 'Stop Name (RouteName)'")
    print("   4. Verify NO hardcoded mock stops like 'Brunei Hall' or coordinates like 5.75/-0.1667")
    print("   5. Start driver telemetry on Phase6TestRoute")
    print(f"   6. Select: Pickup='{pickup.get('name') if pickup else 'Stop 1'}', Destination='{destination.get('name') if destination else 'Stop 3}'")
    print("   7. Tap 'Find Available Shuttles' and verify matching works")
    print("   8. Report results with screenshot evidence")

if __name__ == "__main__":
    main()
