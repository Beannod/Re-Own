from sqlalchemy import Column, Integer, String, Float, ForeignKey, DateTime, Text
from sqlalchemy.sql import func
from ..database import Base

class Property(Base):
    __tablename__ = "properties"

    id = Column(Integer, primary_key=True, index=True)
    owner_id = Column(Integer, ForeignKey("users.id"))
    title = Column(String(200))
    address = Column(String(500))
    property_type = Column(String(50))  # house, apartment, etc.
    bedrooms = Column(Integer)
    bathrooms = Column(Integer)
    area = Column(Float)
    rent_amount = Column(Float)
    description = Column(Text)
    status = Column(String(50))  # available, rented, maintenance
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    updated_at = Column(DateTime(timezone=True), onupdate=func.now())
