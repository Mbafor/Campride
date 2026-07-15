from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from app.api.v1.auth import router as auth_router, admin_router as auth_admin_router
from app.api.v1.shuttles import admin_router as shuttles_admin_router, public_router as shuttles_public_router
from app.api.v1.routes import admin_router as routes_admin_router, admin_stops_router, public_router as routes_public_router
from app.api.v1.driver import router as driver_router
from app.api.v1.fleet import router as fleet_router

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


@app.get("/health")
def health_check():
    return {"status": "ok"}
