from pydantic import BaseModel
from typing import Optional
from datetime import datetime


class MaintenanceCreate(BaseModel):
    unit_id: int
    tenant_id: Optional[int] = None
    details: str
    priority: Optional[str] = "normal"  # low, normal, high, urgent
    photo_url: Optional[str] = None


class Maintenance(BaseModel):
    id: int
    unit_id: int
    tenant_id: Optional[int]
    details: str
    status: str  # pending, in_progress, resolved, cancelled
    priority: Optional[str]
    created_at: datetime
    updated_at: Optional[datetime]

    class Config:
        from_attributes = True


class MaintenanceStatusUpdate(BaseModel):
    status: str
