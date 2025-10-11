from pydantic import BaseModel
from typing import Optional
from datetime import datetime

class PropertyBase(BaseModel):
    title: str
    address: str
    property_type: str
    bedrooms: int
    bathrooms: int
    area: float
    rent_amount: float
    deposit_amount: Optional[float] = None
    description: Optional[str] = None
    status: str

class PropertyCreate(PropertyBase):
    pass

class PropertyUpdate(PropertyBase):
    pass

class Property(PropertyBase):
    id: int
    owner_id: int
    created_at: datetime
    updated_at: Optional[datetime]

    class Config:
        from_attributes = True
