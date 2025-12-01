from fastapi import APIRouter, HTTPException, status, Depends
from typing import List, Dict
from ..database import StoredProcedures
from ..core.dependencies import require_owner_access

router = APIRouter(prefix="/lookups", tags=["Lookups"])

@router.get("/property-types")
def get_property_types() -> List[Dict]:
    rows = StoredProcedures.execute_sp("sp_GetPropertyTypes") or []
    return rows

@router.post("/property-types")
def add_property_type(type_name: str, description: str = None, is_active: bool = True, current_user: dict = Depends(require_owner_access)):
    # Owners can add new types; in future restrict to admin if needed
    try:
        res = StoredProcedures.execute_sp("sp_AddPropertyType", [type_name, description, int(bool(is_active))])
        affected = (res and res[0].get('AffectedRows')) if isinstance(res, list) and res else 0
        return {"affected": affected}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e), headers={"X-Error-Code": "ADD_PROPERTY_TYPE_FAILED"})
