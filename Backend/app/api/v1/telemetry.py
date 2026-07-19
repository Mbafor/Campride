import json
import uuid
from datetime import datetime, timezone, timedelta
from math import radians, cos, sin, asin, sqrt
from fastapi import APIRouter, WebSocket, WebSocketDisconnect, Query, Depends, HTTPException
from sqlalchemy.orm import Session

from app.database import SessionLocal
from app.models import User, Trip, TelemetryLog, Shuttle, DriverCurrentRoute
from app.core.redis_client import update_driver_location, get_driver_location
from app.core.security import decode_token
from app.api.deps import get_db

router = APIRouter(prefix="/api/v1/ws", tags=["telemetry"])

DISTANCE_FILTER_METERS = 2.0
MIN_LAT = -90
MAX_LAT = 90
MIN_LNG = -180
MAX_LNG = 180
NULL_ISLAND_THRESHOLD = 0.001


def haversine_distance(lat1: float, lng1: float, lat2: float, lng2: float) -> float:
    """Calculate distance in meters between two lat/lng coordinates"""
    lat1, lng1, lat2, lng2 = map(radians, [lat1, lng1, lat2, lng2])
    dlat = lat2 - lat1
    dlng = lng2 - lng1
    a = sin(dlat / 2) ** 2 + cos(lat1) * cos(lat2) * sin(dlng / 2) ** 2
    c = 2 * asin(sqrt(a))
    r = 6371000  # Radius of earth in meters
    return c * r


def is_null_island(lat: float, lng: float) -> bool:
    """Check if coordinates are at Null Island (0, 0)"""
    return abs(lat) < NULL_ISLAND_THRESHOLD and abs(lng) < NULL_ISLAND_THRESHOLD


def validate_coordinates(lat: float, lng: float) -> tuple[bool, str]:
    """Validate latitude and longitude. Returns (is_valid, error_message)"""
    if not isinstance(lat, (int, float)) or not isinstance(lng, (int, float)):
        return False, "Latitude and longitude must be numbers"

    if is_null_island(lat, lng):
        return False, "Null Island coordinates rejected"

    if lat < MIN_LAT or lat > MAX_LAT:
        return False, f"Latitude out of range [{MIN_LAT}, {MAX_LAT}]"

    if lng < MIN_LNG or lng > MAX_LNG:
        return False, f"Longitude out of range [{MIN_LNG}, {MAX_LNG}]"

    return True, ""


def get_driver_from_token(token: str, db: Session) -> User | None:
    """Extract driver from JWT token. Returns User if valid driver, None otherwise."""
    try:
        payload = decode_token(token)
        user_id = payload.get("sub")
        if not user_id:
            return None

        user = db.query(User).filter(User.id == user_id).first()
        if not user or user.role != "driver":
            return None

        return user
    except Exception:
        return None


@router.websocket("/driver/telemetry")
async def telemetry_websocket(
    websocket: WebSocket,
    token: str = Query(...),
):
    """
    WebSocket endpoint for driver telemetry (location updates).

    Authentication: JWT token passed as query parameter (?token=...)
    Query param is used instead of header because WebSocket clients have better compatibility with query params.

    Expected message format:
    {
        "lat": float,
        "lng": float,
        "heading": float,
        "accuracy": float,
        "timestamp": ISO8601 string
    }
    """
    db = SessionLocal()
    driver = None
    trip = None

    try:
        # Authenticate driver
        driver = get_driver_from_token(token, db)
        if not driver:
            await websocket.close(code=1008, reason="Invalid or missing JWT token")
            return

        # Check if driver has assigned shuttle
        shuttle = db.query(Shuttle).filter(Shuttle.driver_id == driver.id).first()
        if not shuttle:
            await websocket.close(code=1008, reason="No shuttle assigned to this driver")
            return

        # Check if driver has assigned route
        driver_route = db.query(DriverCurrentRoute).filter(DriverCurrentRoute.driver_id == driver.id).first()
        if not driver_route or not driver_route.route_id:
            await websocket.close(code=1008, reason="No route assigned to this driver")
            return

        await websocket.accept()

        # Look for active trip or create new one
        trip = db.query(Trip).filter(
            Trip.driver_id == driver.id,
            Trip.status == "active"
        ).first()

        if not trip:
            trip = Trip(
                id=uuid.uuid4(),
                driver_id=driver.id,
                shuttle_id=shuttle.id,
                route_id=driver_route.route_id,
                status="active",
                started_at=datetime.utcnow()
            )
            db.add(trip)
            db.commit()
            db.refresh(trip)

        await websocket.send_json({"status": "connected", "message": "Telemetry connection established"})

        # Listen for location updates
        while True:
            message = await websocket.receive_text()
            data = json.loads(message)

            # Extract and validate fields
            lat = data.get("lat")
            lng = data.get("lng")
            heading = data.get("heading", 0)
            accuracy = data.get("accuracy", 0)
            timestamp_str = data.get("timestamp")

            # Validate coordinates
            valid, error_msg = validate_coordinates(lat, lng)
            if not valid:
                await websocket.send_json({
                    "status": "rejected",
                    "reason": error_msg
                })
                continue

            # Validate accuracy
            if not isinstance(accuracy, (int, float)) or accuracy < 0:
                await websocket.send_json({
                    "status": "rejected",
                    "reason": "Accuracy must be a non-negative number"
                })
                continue

            # Validate timestamp
            try:
                if timestamp_str:
                    timestamp = datetime.fromisoformat(timestamp_str.replace('Z', '+00:00'))
                else:
                    timestamp = datetime.utcnow()

                # Reject future timestamps (allow 30 seconds of clock skew for distributed systems)
                now = datetime.now(timezone.utc) if timestamp.tzinfo else datetime.utcnow()
                if timestamp.tzinfo is None:
                    timestamp = timestamp.replace(tzinfo=timezone.utc)
                # Allow 30 seconds of clock skew (client and server clocks may differ)
                max_future = now.replace(tzinfo=timezone.utc) + timedelta(seconds=30)
                if timestamp > max_future:
                    await websocket.send_json({
                        "status": "rejected",
                        "reason": "Timestamp is in the future"
                    })
                    continue
            except ValueError:
                await websocket.send_json({
                    "status": "rejected",
                    "reason": "Invalid timestamp format"
                })
                continue

            # Distance filtering: check against last known position
            driver_id_str = str(driver.id)
            last_location = get_driver_location(driver_id_str)

            # DEBUG
            import sys
            print(f"[DEBUG] Driver: {driver_id_str}, Last: {last_location}", file=sys.stderr)

            if last_location:
                distance = haversine_distance(
                    lat, lng,
                    last_location["lat"], last_location["lng"]
                )
                print(f"[DEBUG] Distance: {distance:.2f}m, Threshold: {DISTANCE_FILTER_METERS}m", file=sys.stderr)
                if distance < DISTANCE_FILTER_METERS:
                    await websocket.send_json({
                        "status": "filtered",
                        "reason": f"New position too close to last position ({distance:.2f}m < {DISTANCE_FILTER_METERS}m)"
                    })
                    continue
            else:
                print(f"[DEBUG] No last location found in Redis", file=sys.stderr)

            # Update Redis location - MUST succeed for distance filtering to work
            update_result = update_driver_location(driver_id_str, lat, lng, heading, accuracy)
            print(f"[DEBUG] Redis update result: {update_result}", file=sys.stderr)
            if not update_result:
                await websocket.send_json({
                    "status": "error",
                    "message": "Failed to update location in Redis"
                })
                continue

            # Log telemetry to database
            from geoalchemy2.elements import WKTElement
            telemetry = TelemetryLog(
                id=uuid.uuid4(),
                driver_id=driver.id,
                trip_id=trip.id,
                location=WKTElement(f"POINT({lng} {lat})", srid=4326),
                accuracy=accuracy,
                heading=heading,
                timestamp=timestamp
            )
            db.add(telemetry)
            db.commit()

            await websocket.send_json({
                "status": "accepted",
                "message": "Location update recorded",
                "lat": lat,
                "lng": lng
            })

    except WebSocketDisconnect:
        # Driver disconnected - log but don't remove from Redis or end trip
        # Stale cleanup and explicit offline endpoint will handle that
        print(f"Driver {driver.id if driver else 'unknown'} disconnected from telemetry WebSocket")
    except Exception as e:
        print(f"WebSocket error: {e}")
        try:
            await websocket.send_json({
                "status": "error",
                "message": str(e)
            })
        except:
            pass
    finally:
        db.close()
