import uuid
from datetime import datetime
from sqlalchemy import Column, String, DateTime
from sqlalchemy.dialects.postgresql import UUID
from geoalchemy2 import Geometry
from app.database import Base


class Route(Base):
    __tablename__ = "routes"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    name = Column(String, nullable=False)
    start_location = Column(Geometry("POINT", srid=4326), nullable=False)
    end_location = Column(Geometry("POINT", srid=4326), nullable=False)
    start_name = Column(String, nullable=False)
    end_name = Column(String, nullable=False)
    created_at = Column(DateTime, default=datetime.utcnow)
