"""
Test script for ETA calculation — run this to validate the math.
Test cases with known distances to verify calculations.
"""
import sys
import math

sys.path.insert(0, 'c:\\Users\\Ernest Mpiani\\OneDrive\\Documents\\portfolio projects\\Campride\\Backend')

from app.core.eta import haversine_distance, calculate_straight_line_eta


def test_haversine_distances():
    """Test haversine with known distances."""
    print("\n=== HAVERSINE DISTANCE TESTS ===\n")

    # Test 1: Accra center to Accra 2km north (approximate)
    lat1, lng1 = 5.6037, -0.1870  # Accra center
    lat2, lng2 = 5.6237, -0.1870  # ~2km north

    distance = haversine_distance(lat1, lng1, lat2, lng2)
    print(f"Test 1: Accra center to 2km north")
    print(f"  Coordinates: ({lat1}, {lng1}) to ({lat2}, {lng2})")
    print(f"  Calculated distance: {distance:.0f} meters ({distance/1000:.2f} km)")
    print(f"  Expected: ~2000m - {('PASS' if 1900 <= distance <= 2100 else 'FAIL')}")

    # Test 2: Same location (should be 0)
    distance = haversine_distance(lat1, lng1, lat1, lng1)
    print(f"\nTest 2: Same location")
    print(f"  Distance: {distance:.0f} meters")
    print(f"  Expected: 0m - {('PASS' if distance < 1 else 'FAIL')}")

    # Test 3: Accra to Tema (~25km east)
    lat1, lng1 = 5.6037, -0.1870  # Accra
    lat2, lng2 = 5.6270, 0.0100   # Tema

    distance = haversine_distance(lat1, lng1, lat2, lng2)
    print(f"\nTest 3: Accra to Tema (~25km)")
    print(f"  Calculated distance: {distance:.0f} meters ({distance/1000:.2f} km)")
    print(f"  Expected: ~25000m - {('PASS' if 24000 <= distance <= 26000 else 'FAIL')}")


def test_straight_line_eta():
    """Test straight-line ETA calculations."""
    print("\n=== STRAIGHT-LINE ETA TESTS ===\n")

    # Test 1: 2km away at 20km/h should be 6 minutes
    lat1, lng1 = 5.6037, -0.1870
    lat2, lng2 = 5.6237, -0.1870

    eta_minutes, distance = calculate_straight_line_eta(lat1, lng1, lat2, lng2)
    print(f"Test 1: 2km away at 20km/h = 6 minutes")
    print(f"  Distance: {distance:.0f}m ({distance/1000:.2f}km)")
    print(f"  ETA: {eta_minutes} minutes")
    print(f"  Expected: 6 minutes - {('PASS' if eta_minutes == 6 else 'FAIL')}")

    # Test 2: 25km away should be 75 minutes (1.25 hours x 60)
    lat1, lng1 = 5.6037, -0.1870
    lat2, lng2 = 5.6270, 0.0100

    eta_minutes, distance = calculate_straight_line_eta(lat1, lng1, lat2, lng2)
    print(f"\nTest 2: ~25km away at 20km/h = ~75 minutes")
    print(f"  Distance: {distance:.0f}m ({distance/1000:.2f}km)")
    print(f"  ETA: {eta_minutes} minutes")
    print(f"  Expected: ~75 minutes - {('PASS' if 72 <= eta_minutes <= 78 else 'FAIL')}")

    # Test 3: 1km away should be 3 minutes
    lat1, lng1 = 5.6037, -0.1870
    lat2, lng2 = 5.6087, -0.1870

    eta_minutes, distance = calculate_straight_line_eta(lat1, lng1, lat2, lng2)
    print(f"\nTest 3: ~1km away at 20km/h = ~3 minutes")
    print(f"  Distance: {distance:.0f}m ({distance/1000:.2f}km)")
    print(f"  ETA: {eta_minutes} minutes")
    print(f"  Expected: ~3 minutes - {('PASS' if 2 <= eta_minutes <= 4 else 'FAIL')}")

    # Test 4: 500m away should be 1.5 minutes (rounds to 2 minutes minimum)
    lat1, lng1 = 5.6037, -0.1870
    lat2_offset = 500 / 111000  # Very rough: 1 degree latitude ~= 111km
    lat2, lng2 = 5.6037 + lat2_offset, -0.1870

    eta_minutes, distance = calculate_straight_line_eta(lat1, lng1, lat2, lng2)
    print(f"\nTest 4: ~500m away at 20km/h = ~1.5 minutes (min 1)")
    print(f"  Distance: {distance:.0f}m ({distance/1000:.2f}km)")
    print(f"  ETA: {eta_minutes} minutes")
    print(f"  Expected: 1-2 minutes - {('PASS' if 1 <= eta_minutes <= 2 else 'FAIL')}")


if __name__ == '__main__':
    test_haversine_distances()
    test_straight_line_eta()
    print("\n" + "="*50)
    print("ETA calculation tests complete")
    print("="*50 + "\n")
