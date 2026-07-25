import json
import asyncio
from datetime import datetime
from fastapi import APIRouter, WebSocket, WebSocketDisconnect, Query, Depends
from app.core.redis_client import get_all_live_locations
from app.core.security import decode_token
from app.models import User, ShuttleRequest, Trip, Notification, Route, Stop, NotificationType
from app.database import SessionLocal
import redis
from app.core.config import settings
from app.core.notifications import send_push_notification
from app.core.eta import haversine_distance
from geoalchemy2.shape import to_shape
import sys

router = APIRouter(prefix="/api/v1/ws", tags=["live-map"])

# Track connected live-map clients
connected_clients = set()
clients_lock = asyncio.Lock()


async def broadcast_location_update(message: dict):
    """Broadcast a location update to all connected live-map clients"""
    if not connected_clients:
        return

    # Create a copy to avoid modifying during iteration
    clients_copy = connected_clients.copy()

    for client_ws in clients_copy:
        try:
            await client_ws.send_json(message)
        except Exception as e:
            print(f"[LIVE-MAP] Error broadcasting to client: {type(e).__name__}: {e}", file=sys.stderr)
            # Remove disconnected client
            try:
                await clients_lock.acquire()
                connected_clients.discard(client_ws)
                clients_lock.release()
            except:
                pass


def _check_and_trigger_notifications(driver_id: str, shuttle_lat: float, shuttle_lng: float, db) -> None:
    """Check for matched shuttle requests and trigger notifications based on distance thresholds."""
    try:
        # Find all matched shuttle requests for this driver
        matched_requests = db.query(ShuttleRequest).join(
            Trip, ShuttleRequest.matched_trip_id == Trip.id
        ).filter(
            Trip.driver_id == driver_id,
            ShuttleRequest.status == "matched"
        ).all()

        for request in matched_requests:
            try:
                # Extract pickup coordinates
                pickup_point = to_shape(request.pickup_location)
                pickup_lat = pickup_point.y
                pickup_lng = pickup_point.x

                # Calculate distance to pickup
                distance_to_pickup = haversine_distance(shuttle_lat, shuttle_lng, pickup_lat, pickup_lng)

                # Get the route to calculate stops away
                trip = db.query(Trip).filter(Trip.id == request.matched_trip_id).first()
                if not trip:
                    continue

                route = db.query(Route).filter(Route.id == trip.route_id).first()
                if not route:
                    continue

                stops = db.query(Stop).filter(Stop.route_id == route.id).order_by(Stop.order).all()

                # Find closest stop before pickup
                shuttle_point = (shuttle_lat, shuttle_lng)
                closest_stop_idx = 0
                closest_distance = float('inf')

                for idx, stop in enumerate(stops):
                    try:
                        stop_point = to_shape(stop.location)
                        stop_lat = stop_point.y
                        stop_lng = stop_point.x
                        dist = haversine_distance(shuttle_lat, shuttle_lng, stop_lat, stop_lng)
                        if dist < closest_distance:
                            closest_distance = dist
                            closest_stop_idx = idx
                    except:
                        continue

                # Find pickup stop index
                pickup_stop_idx = None
                for idx in range(closest_stop_idx, len(stops)):
                    stop = stops[idx]
                    try:
                        stop_point = to_shape(stop.location)
                        stop_lat = stop_point.y
                        stop_lng = stop_point.x
                        dist = haversine_distance(pickup_lat, pickup_lng, stop_lat, stop_lng)
                        if dist < 300:  # Within threshold
                            pickup_stop_idx = idx
                            break
                    except:
                        continue

                if pickup_stop_idx is None:
                    continue

                # Determine notification threshold
                new_threshold = None
                if distance_to_pickup < 50:
                    new_threshold = "shuttle_arrived"
                elif distance_to_pickup < 500:
                    new_threshold = "shuttle_nearby"
                elif closest_stop_idx <= pickup_stop_idx - 5:
                    new_threshold = "five_stops_away"
                else:
                    new_threshold = "shuttle_heading_your_way"

                # Check if this is a new threshold
                if request.last_notification_level == new_threshold:
                    continue  # Already notified for this threshold

                # Create Notification record
                notification = Notification(
                    user_id=request.student_id,
                    trip_id=request.matched_trip_id,
                    type=NotificationType[new_threshold],
                    message=f"Your shuttle is {new_threshold.replace('_', ' ')}"
                )
                db.add(notification)
                db.commit()
                db.refresh(notification)

                print(f"[NOTIFICATIONS] Created notification {notification.id} for student {request.student_id}: {new_threshold}", file=sys.stderr)

                # Get student FCM token and send push notification
                student = db.query(User).filter(User.id == request.student_id).first()
                if student and student.fcm_token:
                    try:
                        send_push_notification(
                            fcm_token=student.fcm_token,
                            title=f"Shuttle Update",
                            body=f"Your shuttle is {new_threshold.replace('_', ' ')}",
                            data_payload={"notification_id": str(notification.id), "trip_id": str(request.matched_trip_id)}
                        )
                        print(f"[NOTIFICATIONS] Sent push notification to {student.email} for {new_threshold}", file=sys.stderr)
                    except Exception as e:
                        print(f"[NOTIFICATIONS] Failed to send push for {student.email}: {e}", file=sys.stderr)
                else:
                    print(f"[NOTIFICATIONS] No FCM token for student {request.student_id}", file=sys.stderr)

                # Update last_notification_level
                request.last_notification_level = new_threshold
                db.commit()

            except Exception as e:
                print(f"[NOTIFICATIONS] Error processing request {request.id}: {e}", file=sys.stderr)
                import traceback
                traceback.print_exc(file=sys.stderr)

    except Exception as e:
        print(f"[NOTIFICATIONS] Error in _check_and_trigger_notifications: {e}", file=sys.stderr)
        import traceback
        traceback.print_exc(file=sys.stderr)


def _redis_pubsub_listener(queue: asyncio.Queue):
    """Run Redis pub/sub in a synchronous thread and put messages in async queue"""
    try:
        print("[LIVE-MAP-SUB] Starting Redis subscription in thread", file=sys.stderr)
        redis_client = redis.from_url(settings.REDIS_URL, decode_responses=True)
        pubsub = redis_client.pubsub()
        pubsub.subscribe("driver-location-updates")
        print("[LIVE-MAP-SUB] Subscribed to driver-location-updates channel", file=sys.stderr)

        for message in pubsub.listen():
            if message['type'] == 'message':
                # Put message in the queue for the async broadcast handler
                try:
                    asyncio.run_coroutine_threadsafe(queue.put(message['data']), queue._loop)
                except Exception as e:
                    print(f"[LIVE-MAP-SUB] Error putting message in queue: {e}", file=sys.stderr)

    except Exception as e:
        print(f"[LIVE-MAP-SUB] Exception in Redis listener: {type(e).__name__}: {e}", file=sys.stderr)
        import traceback
        traceback.print_exc(file=sys.stderr)


async def live_map_subscription_task():
    """Background task that handles Redis pub/sub messages and broadcasts to live-map clients"""
    print("[LIVE-MAP-SUB] Starting live map subscription task", file=sys.stderr)

    try:
        # Create a queue to receive messages from the Redis subscription thread
        message_queue = asyncio.Queue()
        message_queue._loop = asyncio.get_event_loop()

        # Start the Redis subscription in a thread pool
        loop = asyncio.get_event_loop()
        loop.run_in_executor(None, _redis_pubsub_listener, message_queue)

        # Listen for messages from the queue and broadcast them
        while True:
            try:
                # Get message from queue with timeout
                message_data = await asyncio.wait_for(message_queue.get(), timeout=60.0)

                try:
                    update_data = json.loads(message_data)
                    driver_id = update_data.get('driver_id')
                    shuttle_lat = update_data.get('lat')
                    shuttle_lng = update_data.get('lng')

                    print(f"[LIVE-MAP-SUB] Received update for driver {driver_id}", file=sys.stderr)

                    # Check for matched requests and trigger notifications
                    if driver_id and shuttle_lat is not None and shuttle_lng is not None:
                        db = SessionLocal()
                        try:
                            _check_and_trigger_notifications(driver_id, shuttle_lat, shuttle_lng, db)
                        finally:
                            db.close()

                    # Broadcast to all connected clients
                    await broadcast_location_update({
                        "type": "driver_location_update",
                        "data": update_data
                    })

                except json.JSONDecodeError as e:
                    print(f"[LIVE-MAP-SUB] Error parsing message: {e}", file=sys.stderr)
                except Exception as e:
                    print(f"[LIVE-MAP-SUB] Error processing message: {type(e).__name__}: {e}", file=sys.stderr)

            except asyncio.TimeoutError:
                # Timeout is normal, just continue
                pass
            except Exception as e:
                print(f"[LIVE-MAP-SUB] Error in queue listener: {type(e).__name__}: {e}", file=sys.stderr)

    except Exception as e:
        print(f"[LIVE-MAP-SUB] Exception in subscription task: {type(e).__name__}: {e}", file=sys.stderr)
        import traceback
        traceback.print_exc(file=sys.stderr)


@router.websocket("/live-map")
async def live_map_websocket(websocket: WebSocket, token: str = Query(...)):
    """
    Student-facing live map WebSocket endpoint.
    Broadcasts real-time driver location updates to all connected clients.

    Authentication: any authenticated user (student, driver, fleet_manager, super_admin)
    Query param: token (JWT)
    """
    # Authenticate
    try:
        payload = decode_token(token)
        user_id = payload.get("sub")
        if not user_id:
            await websocket.close(code=4001, reason="Invalid token")
            return
    except Exception as e:
        print(f"[LIVE-MAP] Authentication error: {type(e).__name__}: {e}", file=sys.stderr)
        await websocket.close(code=4001, reason="Authentication failed")
        return

    # Accept connection
    await websocket.accept()
    print(f"[LIVE-MAP] Client connected: {user_id}", file=sys.stderr)

    # Add to connected clients
    async with clients_lock:
        connected_clients.add(websocket)
    print(f"[LIVE-MAP] Total connected clients: {len(connected_clients)}", file=sys.stderr)

    try:
        # Send current snapshot immediately
        print(f"[LIVE-MAP] Sending initial snapshot to {user_id}", file=sys.stderr)
        all_locations = get_all_live_locations()
        await websocket.send_json({
            "type": "initial_snapshot",
            "data": all_locations
        })
        print(f"[LIVE-MAP] Snapshot sent: {len(all_locations)} drivers", file=sys.stderr)

        # Keep connection alive, wait for client disconnect
        while True:
            # This will block until client sends a message or disconnects
            # We don't expect any messages from the client, just keep the connection open
            data = await websocket.receive_text()

    except WebSocketDisconnect:
        print(f"[LIVE-MAP] Client disconnected: {user_id}", file=sys.stderr)

    except Exception as e:
        print(f"[LIVE-MAP] Exception: {type(e).__name__}: {e}", file=sys.stderr)
        import traceback
        traceback.print_exc(file=sys.stderr)

    finally:
        # Remove from connected clients
        async with clients_lock:
            connected_clients.discard(websocket)
        print(f"[LIVE-MAP] Client removed. Total connected: {len(connected_clients)}", file=sys.stderr)

        try:
            await websocket.close()
        except:
            pass
