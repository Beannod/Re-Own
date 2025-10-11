from pydantic import BaseModel
from typing import Optional, List
from datetime import date, datetime


class TransactionBase(BaseModel):
    invoice_id: int
    type: str  # rent, water, electricity, internet, maintenance, fee, tax
    description: Optional[str] = None
    amount: float
    due_date: Optional[date] = None


class Transaction(TransactionBase):
    id: int
    created_at: datetime
    updated_at: Optional[datetime]

    class Config:
        from_attributes = True


class InvoiceBase(BaseModel):
    tenant_id: int
    lease_id: int
    period: str  # YYYY-MM
    status: str = "pending"  # pending, paid, partial, overdue


class InvoiceCreate(InvoiceBase):
    pass


class Invoice(InvoiceBase):
    id: int
    total: float
    due_date: date
    created_at: datetime
    updated_at: Optional[datetime]
    transactions: Optional[List[Transaction]] = None

    class Config:
        from_attributes = True
