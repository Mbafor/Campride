import json
import redis
from datetime import datetime
from app.core.config import settings
import sys

print(f"[REDIS] Initializing redis_client...", file=sys.stderr)
print(f"[REDIS] settings.REDIS_URL type: {type(settings.REDIS_URL)}", file=sys.stderr)

redis_url = settings.REDIS_URL if hasattr(settings, 'REDIS_URL') else None
if redis_url:
    # Mask password in logging
    if '@' in redis_url:
        masked = f"redis://***@{redis_url.split('@')[1]}"
    else:
        masked = redis_url
    print(f"[REDIS] REDIS_URL (masked): {masked}", file=sys.stderr)
else:
    print(f"[REDIS] ERROR: REDIS_URL not found in settings!", file=sys.stderr)

try:
    redis_client = redis.from_url(settings.REDIS_URL, decode_responses=True)
    print(f"[REDIS] redis_client created successfully", file=sys.stderr)
    # Test the connection
    redis_client.ping()
    print(f"[REDIS] ping() successful", file=sys.stderr)
except Exception as e:
    print(f"[REDIS] ERROR creating/testing redis_client: {type(e).__name__}: {e}", file=sys.stderr)
    import traceback
    traceback.print_exc(file=sys.stderr)
    redis_client = None


def update_driver_location(driver_id: str, lat: float, lng: float, heading: float, accuracy: float) -> bool:
    """
    Store driver's location in Redis geospatial set and metadata.
    Returns True if successful, False otherwise.
    """
    import sys

    # Check if redis_client initialized
    if redis_client is None:
        print(f"[REDIS] FATAL: redis_client is None - initialization failed!", file=sys.stderr)
        return False

    # Log REDIS_URL at function entry (mask password)
    redis_url = settings.REDIS_URL if hasattr(settings, 'REDIS_URL') else 'NOT SET'
    if redis_url != 'NOT SET':
        # Mask the password: redis://:[PASSWORD]@host -> redis://:***@host
        masked_url = redis_url.split('@')[1] if '@' in redis_url else redis_url
        masked_url = f"redis://***@{masked_url}"
    else:
        masked_url = 'NOT SET'
    print(f"[REDIS] update_driver_location START: REDIS_URL={masked_url}, driver_id={driver_id}, lat={lat}, lng={lng}", file=sys.stderr)

    try:
        # Add to geospatial set (stores lat/lng for proximity queries)
        # redis-py 8.0.1 expects: geoadd(name, values) where values=[lng, lat, member, ...]
        values = [lng, lat, driver_id]
        print(f"[REDIS] Calling geoadd('fleet:live_locations', {values})", file=sys.stderr)
        redis_client.geoadd("fleet:live_locations", values)

        # Store metadata (heading, accuracy, last_updated) in a hash
        metadata = {
            "heading": heading,
            "accuracy": accuracy,
            "last_updated": datetime.utcnow().isoformat()
        }
        print(f"[REDIS] Calling hset(driver:{driver_id}:metadata, {metadata})", file=sys.stderr)
        redis_client.hset(f"driver:{driver_id}:metadata", mapping=metadata)

        print(f"[REDIS] SUCCESS: update_driver_location completed", file=sys.stderr)
        return True
    except Exception as e:
        print(f"[REDIS] EXCEPTION in update_driver_location: {type(e).__name__}: {e}", file=sys.stderr)
        print(f"[REDIS] Full traceback:", file=sys.stderr)
        import traceback
        traceback.print_exc(file=sys.stderr)
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
    import sys

    # Check if redis_client initialized
    if redis_client is None:
        print(f"[REDIS] FATAL: redis_client is None - initialization failed!", file=sys.stderr)
        return None

    try:
        print(f"[REDIS] get_driver_location START: driver_id={driver_id}", file=sys.stderr)

        # Check if driver exists in geospatial set
        rank = redis_client.zrank("fleet:live_locations", driver_id)
        print(f"[REDIS] zrank result: {rank}", file=sys.stderr)
        if rank is None:
            print(f"[REDIS] Driver not in geospatial set, returning None", file=sys.stderr)
            return None

        # Get position
        location = redis_client.geopos("fleet:live_locations", driver_id)
        print(f"[REDIS] geopos result: {location}", file=sys.stderr)
        if not location or not location[0]:
            print(f"[REDIS] No location found, returning None", file=sys.stderr)
            return None

        lng, lat = location[0]

        # Get metadata
        metadata = redis_client.hgetall(f"driver:{driver_id}:metadata")
        print(f"[REDIS] metadata: {metadata}", file=sys.stderr)

        result = {
            "lat": lat,
            "lng": lng,
            "heading": float(metadata.get("heading", 0)),
            "accuracy": float(metadata.get("accuracy", 0)),
            "last_updated": metadata.get("last_updated", "")
        }
        print(f"[REDIS] SUCCESS: returning {result}", file=sys.stderr)
        return result
    except Exception as e:
        print(f"[REDIS] EXCEPTION in get_driver_location: {type(e).__name__}: {e}", file=sys.stderr)
        import traceback
        traceback.print_exc(file=sys.stderr)
        return None


def cleanup_stale_drivers(threshold_seconds: int = 120) -> list[str]:
    """
    Remove drivers who haven't sent a location update in threshold_seconds.
    This handles cases where drivers disconnect without calling /driver/offline
    (e.g. phone died, app crashed, lost signal entirely).

    Returns a list of driver_ids that were removed.
    """
    try:
        cleaned_up = []
        now = datetime.utcnow()

        print(f"[CLEANUP] Starting stale driver cleanup (threshold: {threshold_seconds}s)", file=sys.stderr)

        # Get all drivers currently in the live locations set
        all_locations = get_all_live_locations()
        print(f"[CLEANUP] Found {len(all_locations)} drivers currently tracked", file=sys.stderr)

        for driver_id, location_data in all_locations.items():
            last_updated_str = location_data.get("last_updated", "")

            if not last_updated_str:
                print(f"[CLEANUP] Driver {driver_id}: no last_updated timestamp, skipping", file=sys.stderr)
                continue

            try:
                # Parse the last_updated ISO timestamp
                last_updated = datetime.fromisoformat(last_updated_str)
                time_since_update = (now - last_updated).total_seconds()

                if time_since_update > threshold_seconds:
                    print(f"[CLEANUP] Driver {driver_id}: stale ({time_since_update:.1f}s > {threshold_seconds}s) - removing", file=sys.stderr)

                    # Remove from Redis
                    remove_driver_location(driver_id)
                    cleaned_up.append(driver_id)
                else:
                    print(f"[CLEANUP] Driver {driver_id}: fresh ({time_since_update:.1f}s < {threshold_seconds}s)", file=sys.stderr)

            except Exception as e:
                print(f"[CLEANUP] Error processing driver {driver_id}: {type(e).__name__}: {e}", file=sys.stderr)
                continue

        print(f"[CLEANUP] Cleanup complete: {len(cleaned_up)} drivers removed out of {len(all_locations)} checked", file=sys.stderr)
        return cleaned_up

    except Exception as e:
        print(f"[CLEANUP] EXCEPTION in cleanup_stale_drivers: {type(e).__name__}: {e}", file=sys.stderr)
        import traceback
        traceback.print_exc(file=sys.stderr)
        return []
