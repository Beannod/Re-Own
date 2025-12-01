from sqlalchemy import Column, Integer, String, ForeignKey, DateTime, Text
from sqlalchemy.sql import func
from sqlalchemy.orm import relationship
from ..database import Base

class RenterProfile(Base):
    __tablename__ = 'renter_profiles'

    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey('users.id'), unique=True, index=True)

    emergency_contact = Column(String(100), nullable=True)
    phone_number = Column(String(50), nullable=True)
    current_address = Column(String(500), nullable=True)
    employment_info = Column(String(500), nullable=True)
    tenant_notes = Column(Text, nullable=True)

    created_at = Column(DateTime(timezone=True), server_default=func.now())
    updated_at = Column(DateTime(timezone=True), onupdate=func.now())

    user = relationship('User', back_populates='renter_profile')
