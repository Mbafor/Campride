from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from uuid import UUID
from geoalchemy2.elements import WKTElement

from app.database import SessionLocal
from app.models import Route, Stop, User
from app.schemas.route import RouteCreate, RouteResponse, StopCreate, StopResponse
from app.api.deps import get_db, get_current_user, require_role

admin_router = APIRouter(prefix="/api/v1/admin/routes", tags=["admin-routes"])
admin_stops_router = APIRouter(prefix="/api/v1/admin/stops", tags=["admin-stops"])
public_router = APIRouter(prefix="/api/v1/routes", tags=["routes"])


@admin_router.post("", response_model=RouteResponse)
def create_route(
    route_data: RouteCreate,
    current_user: User = Depends(require_role(["super_admin"])),
    db: Session = Depends(get_db),
):
    start_point = WKTElement(f"POINT({route_data.start_lng} {route_data.start_lat})", srid=4326)
    end_point = WKTElement(f"POINT({route_data.end_lng} {route_data.end_lat})", srid=4326)

    new_route = Route(
        name=route_data.name,
        start_name=route_data.start_name,
        end_name=route_data.end_name,
        start_location=start_point,
        end_location=end_point,
    )
    db.add(new_route)
    db.commit()
    db.refresh(new_route)

    return RouteResponse.from_orm_with_geometry(new_route)


@admin_router.get("", response_model=list[RouteResponse])
def list_routes(
    current_user: User = Depends(require_role(["super_admin"])),
    db: Session = Depends(get_db),
):
    routes = db.query(Route).all()
    return [RouteResponse.from_orm_with_geometry(r) for r in routes]


@public_router.get("/{route_id}", response_model=dict)
def get_route(
    route_id: UUID,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    route = db.query(Route).filter(Route.id == route_id).first()
    if not route:
        raise HTTPException(status_code=404, detail="Route not found")
    return RouteResponse.from_orm_with_geometry(route)


@admin_router.put("/{route_id}", response_model=RouteResponse)
def update_route(
    route_id: UUID,
    route_data: RouteCreate,
    current_user: User = Depends(require_role(["super_admin"])),
    db: Session = Depends(get_db),
):
    route = db.query(Route).filter(Route.id == route_id).first()
    if not route:
        raise HTTPException(status_code=404, detail="Route not found")

    route.name = route_data.name
    route.start_name = route_data.start_name
    route.end_name = route_data.end_name
    route.start_location = WKTElement(f"POINT({route_data.start_lng} {route_data.start_lat})", srid=4326)
    route.end_location = WKTElement(f"POINT({route_data.end_lng} {route_data.end_lat})", srid=4326)

    db.commit()
    db.refresh(route)
    return RouteResponse.from_orm_with_geometry(route)


@admin_router.delete("/{route_id}")
def delete_route(
    route_id: UUID,
    current_user: User = Depends(require_role(["super_admin"])),
    db: Session = Depends(get_db),
):
    route = db.query(Route).filter(Route.id == route_id).first()
    if not route:
        raise HTTPException(status_code=404, detail="Route not found")

    db.delete(route)
    db.commit()
    return {"message": "Route deleted successfully"}


@admin_router.post("/{route_id}/stops", response_model=StopResponse)
def add_stop(
    route_id: UUID,
    stop_data: StopCreate,
    current_user: User = Depends(require_role(["super_admin"])),
    db: Session = Depends(get_db),
):
    route = db.query(Route).filter(Route.id == route_id).first()
    if not route:
        raise HTTPException(status_code=404, detail="Route not found")

    location = WKTElement(f"POINT({stop_data.lng} {stop_data.lat})", srid=4326)
    new_stop = Stop(
        route_id=route_id,
        name=stop_data.name,
        location=location,
        order=stop_data.order,
    )
    db.add(new_stop)
    db.commit()
    db.refresh(new_stop)

    return StopResponse.from_orm_with_geometry(new_stop)


@public_router.get("/{route_id}/stops", response_model=list[dict])
def get_stops(
    route_id: UUID,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    route = db.query(Route).filter(Route.id == route_id).first()
    if not route:
        raise HTTPException(status_code=404, detail="Route not found")

    stops = db.query(Stop).filter(Stop.route_id == route_id).order_by(Stop.order).all()
    return [StopResponse.from_orm_with_geometry(s) for s in stops]


@admin_stops_router.delete("/{stop_id}")
def delete_stop(
    stop_id: UUID,
    current_user: User = Depends(require_role(["super_admin"])),
    db: Session = Depends(get_db),
):
    stop = db.query(Stop).filter(Stop.id == stop_id).first()
    if not stop:
        raise HTTPException(status_code=404, detail="Stop not found")

    db.delete(stop)
    db.commit()
    return {"message": "Stop deleted successfully"}
