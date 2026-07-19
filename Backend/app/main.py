from fastapi import FastAPI, WebSocket, Query
from fastapi.middleware.cors import CORSMiddleware
from app.api.v1.auth import router as auth_router, admin_router as auth_admin_router
from app.api.v1.shuttles import admin_router as shuttles_admin_router, public_router as shuttles_public_router
from app.api.v1.routes import admin_router as routes_admin_router, admin_stops_router, public_router as routes_public_router
from app.api.v1.driver import router as driver_router, close_active_trip
from app.api.v1.fleet import router as fleet_router
from app.api.v1.telemetry import router as telemetry_router
from app.api.v1.live_map import router as live_map_router, live_map_subscription_task
from app.core.redis_client import cleanup_stale_drivers
from app.database import SessionLocal
import json
import asyncio
import sys

app = FastAPI(title="CampRide API", version="1.0.0")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Auth routers
app.include_router(auth_router)
app.include_router(auth_admin_router)

# Shuttle routers
app.include_router(shuttles_admin_router)
app.include_router(shuttles_public_router)

# Route routers
app.include_router(routes_admin_router)
app.include_router(admin_stops_router)
app.include_router(routes_public_router)

# Driver routers
app.include_router(driver_router)

# Fleet manager routers
app.include_router(fleet_router)

# Telemetry routers
app.include_router(telemetry_router)

# Live map routers
app.include_router(live_map_router)


@app.get("/health")
def health_check():
    return {"status": "ok", "version": "websockets_dependency_added_v3"}


@app.websocket("/api/v1/ws/test-direct")
async def test_websocket_direct(websocket: WebSocket):
    """Test WebSocket endpoint registered directly on app (not via router)"""
    await websocket.accept()
    await websocket.send_json({"status": "connected", "message": "This WebSocket was registered directly on app"})


async def stale_driver_cleanup_task(threshold_seconds: int = 120, interval_seconds: int = 30):
    """Background task that periodically removes stale drivers from Redis and closes their trips"""
    print(f"[CLEANUP-TASK] Starting stale driver cleanup task (threshold: {threshold_seconds}s, interval: {interval_seconds}s)", file=sys.stderr)

    while True:
        try:
            # Wait for the interval
            await asyncio.sleep(interval_seconds)

            # Run cleanup
            cleaned_driver_ids = cleanup_stale_drivers(threshold_seconds)

            # For each cleaned up driver, close their active trip
            if cleaned_driver_ids:
                db = SessionLocal()
                try:
                    for driver_id in cleaned_driver_ids:
                        print(f"[CLEANUP-TASK] Closing active trip for driver {driver_id}", file=sys.stderr)
                        trip_result = close_active_trip(driver_id, db)
                        if trip_result["closed"]:
                            print(f"[CLEANUP-TASK] Trip {trip_result['trip_id']} closed for driver {driver_id}", file=sys.stderr)
                        else:
                            print(f"[CLEANUP-TASK] No active trip found for driver {driver_id}", file=sys.stderr)
                finally:
                    db.close()

        except Exception as e:
            print(f"[CLEANUP-TASK] Exception in cleanup loop: {type(e).__name__}: {e}", file=sys.stderr)
            import traceback
            traceback.print_exc(file=sys.stderr)
            # Continue looping even on error


@app.on_event("startup")
async def startup_event():
    """Log all registered routes and spawn background cleanup task"""
    print("\n" + "="*80, file=sys.stderr)
    print("ALL ROUTES (using app.routes)", file=sys.stderr)
    print("="*80, file=sys.stderr)

    # Use app.routes which should merge all routes
    all_routes = app.routes

    websocket_routes = []
    other_routes = []

    for route in all_routes:
        route_type = route.__class__.__name__
        path = getattr(route, 'path', 'UNKNOWN')

        if 'WebSocket' in route_type:
            websocket_routes.append((route_type, path))
        else:
            other_routes.append((route_type, path))

    print(f"\nHTTP ROUTES ({len(other_routes)}):", file=sys.stderr)
    for route_type, path in other_routes[:20]:  # First 20
        methods = getattr([r for r in all_routes if getattr(r, 'path', None) == path][0], 'methods', 'N/A') if path != 'UNKNOWN' else 'N/A'
        print(f"  {route_type:20} {path}", file=sys.stderr)

    print(f"\nWEBSOCKET ROUTES ({len(websocket_routes)}):", file=sys.stderr)
    for route_type, path in websocket_routes:
        print(f"  {route_type:20} {path}", file=sys.stderr)

    if not websocket_routes:
        print("  NONE FOUND!", file=sys.stderr)

    print("="*80 + "\n", file=sys.stderr)

    # Spawn the background cleanup task
    print("[STARTUP] Spawning stale driver cleanup background task", file=sys.stderr)
    asyncio.create_task(stale_driver_cleanup_task(threshold_seconds=120, interval_seconds=30))

    # Spawn the live map subscription task
    print("[STARTUP] Spawning live map subscription task", file=sys.stderr)
    asyncio.create_task(live_map_subscription_task())
