from sqlalchemy import Column, Integer, String, Boolean, DateTime, Text
from sqlalchemy.sql import func
from ..database import Base

class User(Base):
    __tablename__ = "users"

    id = Column(Integer, primary_key=True, index=True)
    email = Column(String(255), unique=True, index=True)
    username = Column(String(50), unique=True, index=True)
    hashed_password = Column(String(255))
    full_name = Column(String(100))
    role = Column(String(20))  # 'owner' or 'renter'
    is_active = Column(Boolean, default=True)
    
    # User preferences
    dark_mode = Column(Boolean, default=False)
    notification_preferences = Column(Text)  # JSON string for various notification settings
    
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    updated_at = Column(DateTime(timezone=True), onupdate=func.now())
