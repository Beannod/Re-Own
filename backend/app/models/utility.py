from sqlalchemy import Column, Integer, String, Float, ForeignKey, DateTime
from sqlalchemy.sql import func
from ..database import Base

class Utility(Base):
    __tablename__ = "utilities"

    id = Column(Integer, primary_key=True, index=True)
    property_id = Column(Integer, ForeignKey("properties.id"))
    utility_type = Column(String(50))  # electricity, water, internet
    reading_date = Column(DateTime(timezone=True))
    reading_value = Column(Float)
    amount = Column(Float)
    status = Column(String(50))  # pending, paid
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    updated_at = Column(DateTime(timezone=True), onupdate=func.now())
