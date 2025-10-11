from fastapi import APIRouter, HTTPException
from typing import Optional
from ..database import StoredProcedures

router = APIRouter(
    prefix="/tenants",
    tags=["Tenants"]
)


@router.get("/")
def list_tenants(
    search: Optional[str] = None,
    active_only: Optional[bool] = True
):
    try:
        # Convert boolean to bit for SQL
        active_bit = 1 if active_only else 0 if active_only is False else None
        
        # Use the new sp_GetAllUsers parameters for filtering
        result = StoredProcedures.execute_sp("sp_GetAllUsers", [
            'renter',  # @Role - filter for renters only
            active_bit,  # @IsActive
            search if search else None  # @SearchTerm
        ])
        
        if not result:
            return {"status": "empty", "message": "No tenants found", "tenants": []}
            
        return {"status": "success", "tenants": result}
            
    except Exception as e:
        error_detail = str(e)
        if "RAISERROR" in error_detail:
            # Extract the user-friendly message from SQL error
            error_message = error_detail.split("RAISERROR")[1].strip("() '")
            raise HTTPException(status_code=400, detail=error_message)
        raise HTTPException(status_code=500, detail="Failed to retrieve tenants")


@router.get("/{tenant_id}")
def get_tenant(tenant_id: int):
    result = StoredProcedures.execute_sp("sp_GetUserById", [tenant_id])
    if not result:
        raise HTTPException(status_code=404, detail="Tenant not found")
    return result[0]
