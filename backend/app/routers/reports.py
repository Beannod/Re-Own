from fastapi import APIRouter, Query
from fastapi.responses import JSONResponse
from typing import Optional

router = APIRouter(
    prefix="/reports",
    tags=["Reports"]
)


@router.get("/occupancy")
def occupancy(owner_id: Optional[int] = Query(default=None), start_date: Optional[str] = Query(default=None), end_date: Optional[str] = Query(default=None)):
    """Return occupancy report using sp_GetPropertyOccupancyReport."""
    from ..database import StoredProcedures
    import datetime
    
    def parse_date(d):
        if d is None:
            return None
        try:
            return datetime.datetime.strptime(d, "%Y-%m-%d").date()
        except Exception:
            return None

    def serialize_date(d):
        if isinstance(d, (datetime.date, datetime.datetime)):
            return d.isoformat()
        return d

    def process_row(row):
        if not row or not hasattr(row, 'items'):
            return row
        processed = {}
        try:
            for key, value in row.items():
                processed[key] = serialize_date(value)
            return processed
        except AttributeError:
            # If row is not a dictionary-like object, return it as is
            return row

    params = [owner_id, parse_date(start_date), parse_date(end_date)]
    try:
        results = StoredProcedures.execute_sp("sp_GetPropertyOccupancyReport", params)
        if not results or not results[0]:
            return JSONResponse(status_code=200, content={"data": []})
            
        # Process each row safely
        serialized_results = []
        for row in results[0]:
            try:
                processed = process_row(row)
                serialized_results.append(processed)
            except Exception as e:
                import logging
                logging.error(f"Error processing row: {row}, Error: {str(e)}")
                serialized_results.append(row)  # Include original row if processing fails
                
        return JSONResponse(status_code=200, content={"data": serialized_results})
    except Exception as e:
        return JSONResponse(status_code=500, content={
            "detail": str(e),
            "code": "OCCUPANCY_REPORT_ERROR",
            "params": {"owner_id": owner_id, "start_date": start_date, "end_date": end_date}
        })


@router.get("/payments")
def payments(owner_id: Optional[int] = Query(default=None), start_date: Optional[str] = Query(default=None), end_date: Optional[str] = Query(default=None)):
    """Return payment report using sp_GetPaymentReport."""
    from ..database import StoredProcedures
    # Convert date strings to date objects if provided
    import datetime
    def parse_date(d):
        if d is None:
            return None
        try:
            return datetime.datetime.strptime(d, "%Y-%m-%d").date()
        except Exception:
            return None

    params = [owner_id, parse_date(start_date), parse_date(end_date)]
    try:
        from ..database import StoredProcedures
        results = StoredProcedures.execute_sp("sp_GetPaymentReport", params)
        
        # First resultset has the summary
        if not results or not results[0] or not results[0][0]:
            return JSONResponse(status_code=200, content={
                "monthlyRevenue": 0,
                "totalPayments": 0,
                "pendingAmount": 0,
                "averagePayment": 0,
                "mostCommonType": "rent",
                "totalPropertiesWithPayments": 0,
                "totalPayingTenants": 0,
                "completedPayments": 0,
                "pendingPayments": 0,
                "failedPayments": 0
            })

        try:
            # Get the summary row from first result set
            summary = results[0][0]  # First row of first result set
            
            # Convert pyodbc Row to dict for easier access
            summary_dict = {}
            for key in summary.cursor_description:
                col_name = key[0]
                summary_dict[col_name] = getattr(summary, col_name, None)

            return JSONResponse(status_code=200, content={
                "monthlyRevenue": float(summary_dict.get("monthly_revenue", 0) or 0),
                "totalPayments": int(summary_dict.get("completed_payments", 0) or 0) + int(summary_dict.get("pending_payments", 0) or 0),
                "pendingAmount": float(summary_dict.get("pending_amount", 0) or 0),
                "averagePayment": float(summary_dict.get("average_payment", 0) or 0),
                "mostCommonType": summary_dict.get("most_common_payment_type", "rent") or "rent",
                "totalPropertiesWithPayments": int(summary_dict.get("total_properties_with_payments", 0) or 0),
                "totalPayingTenants": int(summary_dict.get("total_paying_tenants", 0) or 0),
                "completedPayments": int(summary_dict.get("completed_payments", 0) or 0),
                "pendingPayments": int(summary_dict.get("pending_payments", 0) or 0),
                "failedPayments": int(summary_dict.get("failed_payments", 0) or 0)
            })
        except Exception as e:
            import logging
            logging.error(f"Error processing payment report: {e}")
            logging.error(f"Summary object type: {type(summary)}")
            logging.error(f"Summary object: {summary}")
            raise
    except Exception as e:
        return JSONResponse(status_code=500, content={
            "detail": str(e),
            "code": "PAYMENT_REPORT_ERROR",
            "params": {"owner_id": owner_id, "start_date": start_date, "end_date": end_date}
        })


@router.get("/consumption")
def consumption(property_id: Optional[int] = Query(default=None), utility_type: Optional[str] = Query(default=None), start_date: Optional[str] = Query(default=None), end_date: Optional[str] = Query(default=None)):
    """Return utility consumption report using sp_GetUtilityConsumptionReport."""
    from ..database import StoredProcedures
    import datetime

    def parse_date(d):
        if d is None:
            return None
        try:
            return datetime.datetime.strptime(d, "%Y-%m-%d").date()
        except Exception:
            return None

    def serialize_date(d):
        if isinstance(d, (datetime.date, datetime.datetime)):
            return d.isoformat()
        return d

    def process_row(row):
        if not row or not hasattr(row, 'items'):
            return row
        processed = {}
        try:
            for key, value in row.items():
                processed[key] = serialize_date(value)
            return processed
        except AttributeError:
            return row

    params = [property_id, utility_type, parse_date(start_date), parse_date(end_date)]
    try:
        results = StoredProcedures.get_utility_consumption_report(*params)
        if not results:
            return JSONResponse(status_code=200, content={"data": []})

        # Process each row safely
        serialized_results = []
        for row in results:
            try:
                processed = process_row(row)
                serialized_results.append(processed)
            except Exception as e:
                import logging
                logging.error(f"Error processing row: {row}, Error: {str(e)}")
                serialized_results.append(row)  # Include original row if processing fails

        return JSONResponse(status_code=200, content={"data": serialized_results})
    except Exception as e:
        return JSONResponse(status_code=500, content={
            "detail": str(e),
            "code": "CONSUMPTION_REPORT_ERROR",
            "params": {"property_id": property_id, "utility_type": utility_type, "start_date": start_date, "end_date": end_date}
        })
