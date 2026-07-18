import json
import redis
from datetime import datetime
from app.core.config import settings

redis_client = redis.from_url(settings.REDIS_URL, decode_responses=True)


def update_driver_location(driver_id: str, lat: float, lng: float, heading: float, accuracy: float) -> bool:
    """
    Store driver's location in Redis geospatial set and metadata.
    Returns True if successful, False otherwise.
    """
    try:
        # Add to geospatial set (stores lat/lng for proximity queries)
        redis_client.geoadd("fleet:live_locations", lng, lat, driver_id)

        # Store metadata (heading, accuracy, last_updated) in a hash
        metadata = {
            "heading": heading,
            "accuracy": accuracy,
            "last_updated": datetime.utcnow().isoformat()
        }
        redis_client.hset(f"driver:{driver_id}:metadata", mapping=metadata)

        return True
    except Exception as e:
        print(f"Error updating driver location: {e}")
        return False


def get_all_live_locations() -> dict:
    """
    Get all drivers currently in the live locations set with their coordinates and metadata.
    Returns dict: {driver_id: {"lat": float, "lng": float, "heading": float, "accuracy": float, "last_updated": str}}
    """
    try:
        # Get all members of the geospatial set with their positions
        locations = redis_client.geopos("fleet:live_locations")
        members = redis_client.zrange("fleet:live_locations", 0, -1)

        result = {}
        for i, driver_id in enumerate(members):
            if locations[i]:  # geopos can return None for non-existent members
                lng, lat = locations[i]
                # Get metadata
                metadata = redis_client.hgetall(f"driver:{driver_id}:metadata")
                result[driver_id] = {
                    "lat": lat,
                    "lng": lng,
                    "heading": float(metadata.get("heading", 0)),
                    "accuracy": float(metadata.get("accuracy", 0)),
                    "last_updated": metadata.get("last_updated", "")
                }

        return result
    except Exception as e:
        print(f"Error getting all live locations: {e}")
        return {}


def remove_driver_location(driver_id: str) -> bool:
    """
    Remove driver from geospatial set and delete their metadata.
    Returns True if successful, False otherwise.
    """
    try:
        # Remove from geospatial set
        redis_client.zrem("fleet:live_locations", driver_id)

        # Delete metadata hash
        redis_client.delete(f"driver:{driver_id}:metadata")

        return True
    except Exception as e:
        print(f"Error removing driver location: {e}")
        return False


def get_driver_location(driver_id: str) -> dict | None:
    """
    Get a single driver's current position and metadata.
    Returns dict: {"lat": float, "lng": float, "heading": float, "accuracy": float, "last_updated": str}
    or None if driver not found.
    """
    try:
        # Check if driver exists in geospatial set
        rank = redis_client.zrank("fleet:live_locations", driver_id)
        if rank is None:
            return None

        # Get position
        location = redis_client.geopos("fleet:live_locations", driver_id)
        if not location or not location[0]:
            return None

        lng, lat = location[0]

        # Get metadata
        metadata = redis_client.hgetall(f"driver:{driver_id}:metadata")

        return {
            "lat": lat,
            "lng": lng,
            "heading": float(metadata.get("heading", 0)),
            "accuracy": float(metadata.get("accuracy", 0)),
            "last_updated": metadata.get("last_updated", "")
        }
    except Exception as e:
        print(f"Error getting driver location: {e}")
        return None
