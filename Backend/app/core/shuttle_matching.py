"""Shuttle matching logic for student requests."""
from typing import List, Dict, Tuple, Any
from sqlalchemy.orm import Session
from app.models import Trip, Route, Stop, Shuttle
from app.core.redis_client import get_all_live_locations
from app.core.eta import haversine_distance, calculate_eta, calculate_straight_line_eta


def find_matched_shuttles(
    pickup_lat: float,
    pickup_lng: float,
    destination_lat: float,
    destination_lng: float,
    db: Session,
    proximity_threshold_meters: int = 300
) -> List[Dict[str, Any]]:
    """
    Find shuttles whose route actually passes both pickup and destination in correct order.

    A match requires:
    1. A stop within proximity_threshold_meters of pickup location
    2. A LATER stop (higher order) within proximity_threshold_meters of destination
    3. Active driver currently on that route

    Args:
        pickup_lat, pickup_lng: Student's pickup coordinates
        destination_lat, destination_lng: Student's destination coordinates
        db: Database session
        proximity_threshold_meters: How close a stop must be to pickup/destination (default 300m)

    Returns:
        List of matched shuttles with: shuttle_id, name, plate, driver_id, current_lat/lng, ETA, route_name, distance_meters
    """
    matches = []

    try:
        # Get all active drivers from Redis
        live_locations = get_all_live_locations()
        print(f"[Matching] Found {len(live_locations)} active drivers")

        for driver_id, location_data in live_locations.items():
            try:
                shuttle_lat = location_data['lat']
                shuttle_lng = location_data['lng']

                # Find driver's current trip
                trip = db.query(Trip).filter(
                    Trip.driver_id == driver_id,
                    Trip.status == "active"
                ).first()

                if not trip:
                    print(f"[Matching] Driver {driver_id} has no active trip")
                    continue

                # Get the route's ordered stops
                route = db.query(Route).filter(Route.id == trip.route_id).first()
                if not route:
                    print(f"[Matching] Route {trip.route_id} not found for trip {trip.id}")
                    continue

                stops = db.query(Stop).filter(
                    Stop.route_id == route.id
                ).order_by(Stop.order).all()

                if not stops:
                    print(f"[Matching] No stops found for route {route.id}")
                    continue

                print(f"[Matching] Checking driver {driver_id} with {len(stops)} stops on route {route.name}")

                # Find stop closest to pickup
                pickup_stop_idx = None
                pickup_stop_distance = float('inf')

                for idx, stop in enumerate(stops):
                    dist = haversine_distance(pickup_lat, pickup_lng, stop.latitude, stop.longitude)
                    print(f"  [Matching]   Stop {idx} ({stop.name}): {dist:.0f}m from pickup")

                    if dist < pickup_stop_distance:
                        pickup_stop_distance = dist
                        pickup_stop_idx = idx

                # Check if pickup stop is within threshold
                if pickup_stop_distance > proximity_threshold_meters:
                    print(f"[Matching] Pickup stop too far: {pickup_stop_distance:.0f}m > {proximity_threshold_meters}m threshold")
                    continue

                # Find stop closest to destination (must be AFTER pickup stop)
                dest_stop_idx = None
                dest_stop_distance = float('inf')

                for idx in range(pickup_stop_idx + 1, len(stops)):
                    stop = stops[idx]
                    dist = haversine_distance(destination_lat, destination_lng, stop.latitude, stop.longitude)
                    print(f"  [Matching]   Stop {idx} ({stop.name}): {dist:.0f}m from destination")

                    if dist < dest_stop_distance:
                        dest_stop_distance = dist
                        dest_stop_idx = idx

                # Check if destination stop is within threshold and after pickup
                if dest_stop_idx is None or dest_stop_distance > proximity_threshold_meters:
                    print(f"[Matching] No valid destination stop within threshold after pickup")
                    continue

                print(f"[Matching] MATCH FOUND: driver {driver_id} on route {route.name}")

                # Calculate ETA
                eta_minutes, total_distance = calculate_eta(
                    shuttle_lat, shuttle_lng, stops, destination_lat, destination_lng
                )

                # Get shuttle info
                shuttle = db.query(Shuttle).filter(Shuttle.driver_id == driver_id).first()
                shuttle_name = shuttle.name if shuttle else "Unknown"
                plate = shuttle.plate_number if shuttle else "N/A"

                matches.append({
                    'shuttle_id': str(shuttle.id) if shuttle else None,
                    'shuttle_name': shuttle_name,
                    'plate_number': plate,
                    'driver_id': driver_id,
                    'current_lat': shuttle_lat,
                    'current_lng': shuttle_lng,
                    'eta_minutes': eta_minutes,
                    'distance_meters': total_distance,
                    'route_name': route.name,
                    'pickup_stop': stops[pickup_stop_idx].name,
                    'destination_stop': stops[dest_stop_idx].name
                })

            except Exception as e:
                print(f"[Matching] Error processing driver {driver_id}: {e}")
                continue

    except Exception as e:
        print(f"[Matching] Error in find_matched_shuttles: {e}")

    print(f"[Matching] Found {len(matches)} matched shuttles")
    return matches


def find_nearby_shuttles(
    pickup_lat: float,
    pickup_lng: float,
    db: Session,
    exclude_driver_ids: List[str] = None,
    radius_meters: int = 1000
) -> List[Dict[str, Any]]:
    """
    Find any active shuttles within radius of pickup, regardless of route.

    Args:
        pickup_lat, pickup_lng: Student's pickup coordinates
        db: Database session
        exclude_driver_ids: Driver IDs to exclude (e.g., already matched)
        radius_meters: Search radius (default 1000m)

    Returns:
        List of nearby shuttles with: shuttle_id, name, plate, driver_id, current_lat/lng, ETA (straight-line)
    """
    nearby = []
    exclude_driver_ids = exclude_driver_ids or []

    try:
        # Get all active drivers from Redis
        live_locations = get_all_live_locations()
        print(f"[Nearby] Searching {len(live_locations)} active drivers within {radius_meters}m")

        for driver_id, location_data in live_locations.items():
            if driver_id in exclude_driver_ids:
                print(f"[Nearby] Excluding driver {driver_id} (already matched)")
                continue

            try:
                shuttle_lat = location_data['lat']
                shuttle_lng = location_data['lng']

                # Calculate distance to pickup
                distance = haversine_distance(pickup_lat, pickup_lng, shuttle_lat, shuttle_lng)
                print(f"[Nearby] Driver {driver_id}: {distance:.0f}m from pickup")

                if distance > radius_meters:
                    print(f"[Nearby]   Too far (> {radius_meters}m)")
                    continue

                # Calculate straight-line ETA
                eta_minutes, _ = calculate_straight_line_eta(
                    shuttle_lat, shuttle_lng, pickup_lat, pickup_lng
                )

                # Get shuttle info
                shuttle = db.query(Shuttle).filter(Shuttle.driver_id == driver_id).first()
                shuttle_name = shuttle.name if shuttle else "Unknown"
                plate = shuttle.plate_number if shuttle else "N/A"

                nearby.append({
                    'shuttle_id': str(shuttle.id) if shuttle else None,
                    'shuttle_name': shuttle_name,
                    'plate_number': plate,
                    'driver_id': driver_id,
                    'current_lat': shuttle_lat,
                    'current_lng': shuttle_lng,
                    'eta_minutes': eta_minutes,
                    'distance_meters': distance
                })

            except Exception as e:
                print(f"[Nearby] Error processing driver {driver_id}: {e}")
                continue

    except Exception as e:
        print(f"[Nearby] Error in find_nearby_shuttles: {e}")

    print(f"[Nearby] Found {len(nearby)} nearby shuttles")
    return nearby
