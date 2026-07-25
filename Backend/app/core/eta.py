"""ETA calculation helpers for shuttle matching."""
import math
from typing import Tuple


def haversine_distance(lat1: float, lng1: float, lat2: float, lng2: float) -> float:
    """
    Calculate distance between two coordinates using haversine formula.
    Returns distance in meters.
    """
    R = 6371000  # Earth's radius in meters

    lat1_rad = math.radians(lat1)
    lat2_rad = math.radians(lat2)
    delta_lat = math.radians(lat2 - lat1)
    delta_lng = math.radians(lng2 - lng1)

    a = math.sin(delta_lat / 2) ** 2 + math.cos(lat1_rad) * math.cos(lat2_rad) * math.sin(delta_lng / 2) ** 2
    c = 2 * math.asin(math.sqrt(a))

    return R * c


def calculate_straight_line_eta(lat1: float, lng1: float, lat2: float, lng2: float) -> Tuple[int, float]:
    """
    Calculate ETA using straight-line distance (haversine).
    Assumes 20 km/h average shuttle speed.

    Args:
        lat1, lng1: Starting position (shuttle current position)
        lat2, lng2: Destination position

    Returns:
        Tuple of (ETA in minutes, distance in meters)
    """
    distance_meters = haversine_distance(lat1, lng1, lat2, lng2)
    distance_km = distance_meters / 1000

    # 20 km/h speed
    hours = distance_km / 20.0
    minutes = int(round(hours * 60))

    return max(1, minutes), distance_meters  # Minimum 1 minute


def calculate_eta(
    shuttle_current_lat: float,
    shuttle_current_lng: float,
    route_stops_ordered: list,
    destination_lat: float,
    destination_lng: float
) -> Tuple[int, float]:
    """
    Calculate ETA using the shuttle's route and stops.

    Args:
        shuttle_current_lat, shuttle_current_lng: Shuttle's current position
        route_stops_ordered: List of Stop objects in order along the route
        destination_lat, destination_lng: Student's destination coordinates

    Returns:
        Tuple of (ETA in minutes, cumulative distance in meters)
    """
    if not route_stops_ordered:
        # No route stops, use straight-line
        return calculate_straight_line_eta(shuttle_current_lat, shuttle_current_lng, destination_lat, destination_lng)

    # Find the stop closest to shuttle's current position (approximates "where shuttle is on route")
    closest_stop_idx = 0
    closest_distance = float('inf')

    for idx, stop in enumerate(route_stops_ordered):
        dist = haversine_distance(shuttle_current_lat, shuttle_current_lng, stop.latitude, stop.longitude)
        if dist < closest_distance:
            closest_distance = dist
            closest_stop_idx = idx

    # Sum distances: shuttle -> closest stop -> through remaining stops -> to stop nearest destination
    total_distance = closest_distance

    # Find which stop is closest to destination
    dest_stop_idx = 0
    dest_stop_distance = float('inf')

    for idx, stop in enumerate(route_stops_ordered):
        dist = haversine_distance(stop.latitude, stop.longitude, destination_lat, destination_lng)
        if dist < dest_stop_distance:
            dest_stop_distance = dist
            dest_stop_idx = idx

    # Sum cumulative distances from closest_stop to dest_stop
    for i in range(closest_stop_idx, dest_stop_idx):
        if i + 1 < len(route_stops_ordered):
            total_distance += haversine_distance(
                route_stops_ordered[i].latitude,
                route_stops_ordered[i].longitude,
                route_stops_ordered[i + 1].latitude,
                route_stops_ordered[i + 1].longitude
            )

    # Add distance from last stop in route to destination
    total_distance += dest_stop_distance

    distance_km = total_distance / 1000
    hours = distance_km / 20.0
    minutes = int(round(hours * 60))

    return max(1, minutes), total_distance
