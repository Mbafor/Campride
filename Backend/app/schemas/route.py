from uuid import UUID
from datetime import datetime
from typing import Optional
from pydantic import BaseModel
from geoalchemy2.shape import to_shape


class RouteCreate(BaseModel):
    name: str
    start_name: str
    end_name: str
    start_lat: float
    start_lng: float
    end_lat: float
    end_lng: float


class RouteResponse(BaseModel):
    id: UUID
    name: str
    start_name: str
    end_name: str
    start_lat: Optional[float]
    start_lng: Optional[float]
    end_lat: Optional[float]
    end_lng: Optional[float]
    created_at: datetime

    class Config:
        from_attributes = True

    @classmethod
    def from_orm_with_geometry(cls, obj):
        if hasattr(obj, 'start_location') and obj.start_location is not None:
            start_point = to_shape(obj.start_location)
            start_lat, start_lng = start_point.y, start_point.x
        else:
            start_lat, start_lng = None, None

        if hasattr(obj, 'end_location') and obj.end_location is not None:
            end_point = to_shape(obj.end_location)
            end_lat, end_lng = end_point.y, end_point.x
        else:
            end_lat, end_lng = None, None

        return cls(
            id=obj.id,
            name=obj.name,
            start_name=obj.start_name,
            end_name=obj.end_name,
            start_lat=start_lat,
            start_lng=start_lng,
            end_lat=end_lat,
            end_lng=end_lng,
            created_at=obj.created_at,
        )


class StopCreate(BaseModel):
    name: str
    lat: float
    lng: float
    order: int


class StopResponse(BaseModel):
    id: UUID
    route_id: UUID
    name: str
    lat: float
    lng: float
    order: int

    class Config:
        from_attributes = True

    @classmethod
    def from_orm_with_geometry(cls, obj):
        if hasattr(obj, 'location') and obj.location is not None:
            point = to_shape(obj.location)
            lat, lng = point.y, point.x
        else:
            lat, lng = None, None

        return cls(
            id=obj.id,
            route_id=obj.route_id,
            name=obj.name,
            lat=lat,
            lng=lng,
            order=obj.order,
        )
