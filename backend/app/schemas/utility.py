from pydantic import BaseModel
from typing import Optional
from datetime import datetime

class UtilityBase(BaseModel):
    property_id: int
    utility_type: str
    reading_date: datetime
    reading_value: float
    amount: float
    status: str

class UtilityCreate(UtilityBase):
    pass

class UtilityUpdate(BaseModel):
    reading_value: float
    amount: float
    status: str

class Utility(UtilityBase):
    id: int
    created_at: datetime
    updated_at: Optional[datetime]

    class Config:
        from_attributes = True
