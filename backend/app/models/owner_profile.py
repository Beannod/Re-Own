from sqlalchemy import Column, Integer, String, ForeignKey, DateTime, Text
from sqlalchemy.sql import func
from sqlalchemy.orm import relationship
from ..database import Base

class OwnerProfile(Base):
    __tablename__ = 'owner_profiles'

    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey('users.id'), unique=True, index=True)

    company_name = Column(String(200), nullable=True)
    contact_number = Column(String(50), nullable=True)
    address = Column(String(500), nullable=True)
    tax_id = Column(String(100), nullable=True)
    notes = Column(Text, nullable=True)

    created_at = Column(DateTime(timezone=True), server_default=func.now())
    updated_at = Column(DateTime(timezone=True), onupdate=func.now())

    user = relationship('User', back_populates='owner_profile')
