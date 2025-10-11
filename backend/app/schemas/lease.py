from pydantic import BaseModel
from typing import Optional
from datetime import date, datetime


class LeaseBase(BaseModel):
    tenant_id: int
    property_id: int
    start_date: date
    rent_amount: float


class LeaseCreate(LeaseBase):
    pass


class LeaseUpdate(BaseModel):
    start_date: Optional[date] = None
    end_date: Optional[date] = None
    rent_amount: Optional[float] = None
    deposit_amount: Optional[float] = None
    status: Optional[str] = None


class Lease(LeaseBase):
    id: int
    created_at: datetime
    updated_at: Optional[datetime]

    class Config:
        from_attributes = True
