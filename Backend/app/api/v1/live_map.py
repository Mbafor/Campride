import json
import asyncio
from datetime import datetime
from fastapi import APIRouter, WebSocket, WebSocketDisconnect, Query, Depends
from app.core.redis_client import get_all_live_locations
from app.core.security import decode_token
from app.models import User
from app.database import SessionLocal
import redis
from app.core.config import settings
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


async def live_map_subscription_task():
    """Background task that subscribes to Redis pub/sub and broadcasts updates to all live-map clients"""
    print("[LIVE-MAP-SUB] Starting live map subscription task", file=sys.stderr)

    try:
        # Create a separate Redis connection for pub/sub
        redis_client = redis.from_url(settings.REDIS_URL, decode_responses=True)
        pubsub = redis_client.pubsub()

        # Subscribe to driver location updates
        pubsub.subscribe("driver-location-updates")
        print("[LIVE-MAP-SUB] Subscribed to driver-location-updates channel", file=sys.stderr)

        # Listen for messages
        for message in pubsub.listen():
            if message['type'] == 'message':
                try:
                    update_data = json.loads(message['data'])
                    print(f"[LIVE-MAP-SUB] Received update for driver {update_data.get('driver_id')}", file=sys.stderr)

                    # Broadcast to all connected clients
                    await broadcast_location_update({
                        "type": "driver_location_update",
                        "data": update_data
                    })

                except json.JSONDecodeError as e:
                    print(f"[LIVE-MAP-SUB] Error parsing message: {e}", file=sys.stderr)
                except Exception as e:
                    print(f"[LIVE-MAP-SUB] Error processing message: {type(e).__name__}: {e}", file=sys.stderr)

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
