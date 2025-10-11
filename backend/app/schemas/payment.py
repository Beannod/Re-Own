from pydantic import BaseModel
from typing import Optional
from datetime import datetime

class PaymentBase(BaseModel):
    property_id: int
    tenant_id: int
    amount: float
    payment_type: str
    payment_method: str
    payment_status: str
    payment_date: datetime

class PaymentCreate(PaymentBase):
    pass

class PaymentStatusUpdate(BaseModel):
    payment_status: str

class Payment(PaymentBase):
    id: int
    created_at: datetime
    updated_at: Optional[datetime]

    class Config:
        from_attributes = True
