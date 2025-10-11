from fastapi import APIRouter, Query
from fastapi.responses import JSONResponse
from typing import Optional

router = APIRouter(
    prefix="/reports",
    tags=["Reports"]
)


@router.get("/occupancy")
def occupancy(owner_id: Optional[int] = Query(default=None), start_date: Optional[str] = Query(default=None), end_date: Optional[str] = Query(default=None)):
    """Planned: Occupancy report (sp_GetPropertyOccupancyReport)."""
    return JSONResponse(status_code=501, content={
        "detail": "Not implemented",
        "code": "NOT_IMPLEMENTED",
        "hint": "Return occupancy report via sp_GetPropertyOccupancyReport.",
        "params": {"owner_id": owner_id, "start_date": start_date, "end_date": end_date}
    })


@router.get("/collections")
def collections(owner_id: Optional[int] = Query(default=None), start_date: Optional[str] = Query(default=None), end_date: Optional[str] = Query(default=None)):
    """Planned: Payment collection report (sp_GetPaymentCollectionReport)."""
    return JSONResponse(status_code=501, content={
        "detail": "Not implemented",
        "code": "NOT_IMPLEMENTED",
        "hint": "Return collections report via sp_GetPaymentCollectionReport.",
        "params": {"owner_id": owner_id, "start_date": start_date, "end_date": end_date}
    })


@router.get("/consumption")
def consumption(property_id: Optional[int] = Query(default=None), utility_type: Optional[str] = Query(default=None), start_date: Optional[str] = Query(default=None), end_date: Optional[str] = Query(default=None)):
    """Planned: Utility consumption report (sp_GetUtilityConsumptionReport)."""
    return JSONResponse(status_code=501, content={
        "detail": "Not implemented",
        "code": "NOT_IMPLEMENTED",
        "hint": "Return utility consumption via sp_GetUtilityConsumptionReport.",
        "params": {"property_id": property_id, "utility_type": utility_type, "start_date": start_date, "end_date": end_date}
    })
