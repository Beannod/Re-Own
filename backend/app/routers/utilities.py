from fastapi import APIRouter, HTTPException, status, Depends
from ..core.dependencies import get_current_user
from typing import List
from ..database import StoredProcedures
from ..schemas import utility as utility_schema
from datetime import datetime

router = APIRouter(
    prefix="/utilities",
    tags=["Utilities"]
)

@router.get("/", response_model=List[utility_schema.Utility])
def list_utilities(property_id: int = None, current_user: dict = Depends(get_current_user)):
    """
    List all utilities or filter by property_id if provided
    """
    tenant_id = None
    # If renter, restrict to their active lease property utilities implicitly
    if current_user and current_user.get('role') == 'renter':
        tenant_id = current_user.get('user_id')
    params = [property_id, tenant_id]
    result = StoredProcedures.execute_sp("sp_ListUtilities", params)
    if not result:
        return []
    return result

@router.post("/", response_model=utility_schema.Utility)
def create_utility_reading(utility_data: utility_schema.UtilityCreate):
    result = StoredProcedures.create_utility_reading(
        property_id=utility_data.property_id,
        utility_type=utility_data.utility_type,
        reading_date=utility_data.reading_date,
        reading_value=utility_data.reading_value,
        amount=utility_data.amount,
        status=utility_data.status
    )
    
    if not result:
        raise HTTPException(status_code=400, detail="Failed to create utility reading")
    
    return {**utility_data.dict(), "id": result[0]['UtilityId']}

@router.get("/{utility_id}", response_model=utility_schema.Utility)
def get_utility(utility_id: int):
    result = StoredProcedures.execute_sp("sp_GetUtility", [utility_id])
    if not result:
        raise HTTPException(status_code=404, detail="Utility reading not found")
    return result[0]

@router.put("/{utility_id}", response_model=utility_schema.Utility)
def update_utility_reading(utility_id: int, utility_data: utility_schema.UtilityUpdate):
    result = StoredProcedures.update_utility_reading(
        utility_id=utility_id,
        reading_value=utility_data.reading_value,
        amount=utility_data.amount,
        status=utility_data.status
    )
    
    if not result or result[0]['AffectedRows'] == 0:
        raise HTTPException(status_code=404, detail="Utility reading not found")
    
    return {"message": "Utility reading updated successfully"}
