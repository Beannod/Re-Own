from fastapi import APIRouter, HTTPException, status, Depends
from typing import List
from ..database import StoredProcedures
from ..schemas import payment as payment_schema
from ..core.dependencies import get_current_user, require_owner_access
from datetime import datetime

router = APIRouter(
    prefix="/payments",
    tags=["Payments"]
)

@router.get("/")
def list_payments(current_user: dict = Depends(get_current_user)):
    """List payments filtered by role: owners see their properties' payments; renters see their own."""
    try:
        owner_id = None
        tenant_id = None
        if current_user['role'] == 'owner':
            owner_id = current_user['user_id']
        elif current_user['role'] == 'renter':
            tenant_id = current_user['user_id']

        rows = StoredProcedures.execute_sp("sp_ListPayments", [owner_id, tenant_id])
        return rows or []
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@router.post("/", response_model=payment_schema.Payment)
def create_payment(payment_data: payment_schema.PaymentCreate, current_user: dict = Depends(get_current_user)):
    # Verify property ownership if user is an owner, or tenant access if renter
    if current_user['role'] == 'owner':
        # Verify property ownership
        property_result = StoredProcedures.execute_sp("sp_GetProperty", [payment_data.property_id])
        if not property_result or property_result[0]['owner_id'] != current_user['user_id']:
            raise HTTPException(status_code=403, detail="Access denied to this property")
    elif current_user['role'] == 'renter':
        # Verify tenant ID matches
        if payment_data.tenant_id != current_user['user_id']:
            raise HTTPException(status_code=403, detail="Access denied")
    
    result = StoredProcedures.create_payment(
        property_id=payment_data.property_id,
        tenant_id=payment_data.tenant_id,
        amount=payment_data.amount,
        payment_type=payment_data.payment_type,
        payment_method=payment_data.payment_method,
        payment_status=payment_data.payment_status,
        payment_date=payment_data.payment_date
    )
    
    if not result:
        raise HTTPException(status_code=400, detail="Failed to create payment")
    
    return {**payment_data.dict(), "id": result[0]['PaymentId']}

@router.get("/{payment_id}", response_model=payment_schema.Payment)
def get_payment(payment_id: int, current_user: dict = Depends(get_current_user)):
    result = StoredProcedures.get_payment(payment_id)
    if not result:
        raise HTTPException(status_code=404, detail="Payment not found")
    
    payment = result[0]
    
    # Verify access based on role
    if current_user['role'] == 'owner':
        # Verify property ownership
        property_result = StoredProcedures.execute_sp("sp_GetProperty", [payment['property_id']])
        if not property_result or property_result[0]['owner_id'] != current_user['user_id']:
            raise HTTPException(status_code=404, detail="Payment not found")
    elif current_user['role'] == 'renter':
        # Verify tenant access
        if payment['tenant_id'] != current_user['user_id']:
            raise HTTPException(status_code=404, detail="Payment not found")
    
    return payment

@router.put("/{payment_id}/status", response_model=payment_schema.Payment)
def update_payment_status(payment_id: int, status_data: payment_schema.PaymentStatusUpdate):
    result = StoredProcedures.update_payment_status(
        payment_id=payment_id,
        payment_status=status_data.payment_status
    )
    
    if not result or result[0]['AffectedRows'] == 0:
        raise HTTPException(status_code=404, detail="Payment not found")
    
    return {"message": "Payment status updated successfully"}
