from pydantic import BaseModel, EmailStr
from typing import Optional
from datetime import datetime

class UserBase(BaseModel):
    email: EmailStr
    username: str
    full_name: str
    role: str

class UserCreate(UserBase):
    password: str

class UserLogin(BaseModel):
    email: EmailStr
    password: str

class UserPreferences(BaseModel):
    dark_mode: Optional[bool] = None
    notification_preferences: Optional[str] = None

class UserPreferencesUpdate(BaseModel):
    dark_mode: Optional[bool] = None
    notification_preferences: Optional[str] = None

class User(UserBase):
    id: int
    is_active: bool
    dark_mode: Optional[bool] = False
    notification_preferences: Optional[str] = None
    created_at: datetime
    updated_at: Optional[datetime]

    class Config:
        from_attributes = True
