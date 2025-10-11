from fastapi import APIRouter
from fastapi.responses import JSONResponse
from ..schemas import maintenance as maintenance_schema

router = APIRouter(
    prefix="/maintenance",
    tags=["Maintenance"]
)


@router.post("/", response_model=maintenance_schema.Maintenance)
def create_request():
    """Planned: Create maintenance request (sp_CreateMaintenanceRequest)."""
    return JSONResponse(status_code=501, content={
        "detail": "Not implemented",
        "code": "NOT_IMPLEMENTED",
        "hint": "Create maintenance request via sp_CreateMaintenanceRequest."
    })


@router.get("/{request_id}", response_model=maintenance_schema.Maintenance)
def get_request(request_id: int):
    """Planned: Get maintenance request (sp_GetMaintenanceRequest)."""
    return JSONResponse(status_code=501, content={
        "detail": "Not implemented",
        "code": "NOT_IMPLEMENTED",
        "hint": f"Get maintenance request via sp_GetMaintenanceRequest for RequestId={request_id}."
    })


@router.put("/{request_id}/status", response_model=maintenance_schema.Maintenance)
def update_status(request_id: int):
    """Planned: Update maintenance status (sp_UpdateMaintenanceStatus)."""
    return JSONResponse(status_code=501, content={
        "detail": "Not implemented",
        "code": "NOT_IMPLEMENTED",
        "hint": f"Update status via sp_UpdateMaintenanceStatus for RequestId={request_id}."
    })
