from sqlalchemy import Column, Integer, String, Float, ForeignKey, DateTime
from sqlalchemy.sql import func
from ..database import Base

class Payment(Base):
    __tablename__ = "payments"

    id = Column(Integer, primary_key=True, index=True)
    property_id = Column(Integer, ForeignKey("properties.id"))
    tenant_id = Column(Integer, ForeignKey("users.id"))
    amount = Column(Float)
    payment_type = Column(String(50))  # rent, utility, maintenance
    payment_method = Column(String(50))  # cash, bank_transfer, online
    payment_status = Column(String(50))  # pending, completed, failed
    payment_date = Column(DateTime(timezone=True))
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    updated_at = Column(DateTime(timezone=True), onupdate=func.now())
