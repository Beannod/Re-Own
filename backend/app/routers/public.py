from fastapi import APIRouter, HTTPException
from ..database import StoredProcedures
import pyodbc
import logging

router = APIRouter(
    prefix="/public",
    tags=["Public"]
)


def _get_connection():
    last_err = None
    for server in StoredProcedures._candidate_servers():
        try:
            conn_str = StoredProcedures._build_conn_str(server)
            conn = pyodbc.connect(conn_str)
            return conn
        except Exception as e:
            last_err = e
            logging.warning(f"Public summary: connection attempt failed for server '{server}': {e}")
            continue
    raise last_err or Exception("Database connection failed")


@router.get("/summary")
def public_summary():
    """
    Public summary for the landing page: counts, recent properties, and recent collections.
    """
    try:
        conn = _get_connection()
        cur = conn.cursor()

        # Stats
        cur.execute("SELECT COUNT(*) FROM properties")
        total_properties = cur.fetchone()[0] or 0

        cur.execute("SELECT COUNT(*) FROM users WHERE role = 'owner' AND is_active = 1")
        active_owners = cur.fetchone()[0] or 0

        cur.execute("SELECT COUNT(*) FROM users WHERE role = 'renter' AND is_active = 1")
        active_renters = cur.fetchone()[0] or 0

        cur.execute("SELECT COUNT(*) FROM payments")
        total_payments = cur.fetchone()[0] or 0

        # Monthly collections last 6 months (YYYY-MM)
        cur.execute(
            """
            SELECT TOP 6 CONVERT(VARCHAR(7), payment_date, 120) AS ym, SUM(amount) AS total
            FROM payments
            WHERE payment_status = 'completed'
            GROUP BY CONVERT(VARCHAR(7), payment_date, 120)
            ORDER BY ym DESC
            """
        )
        monthly_rows = cur.fetchall() or []
        monthly = [{"month": r[0], "amount": float(r[1] or 0)} for r in monthly_rows][::-1]

        # Recent properties (latest 6)
        cur.execute(
            """
            SELECT TOP 6 p.id, p.title, p.address, p.property_type, p.rent_amount, p.status, p.created_at,
                   u.full_name AS owner_name
            FROM properties p
            LEFT JOIN users u ON u.id = p.owner_id
            ORDER BY p.created_at DESC
            """
        )
        rows = cur.fetchall() or []
        cols = [c[0] for c in cur.description]
        recent_properties = [dict(zip(cols, row)) for row in rows]
        # Cast amounts
        for rp in recent_properties:
            if "rent_amount" in rp and rp["rent_amount"] is not None:
                rp["rent_amount"] = float(rp["rent_amount"])  # ensure JSON serializable

        return {
            "stats": {
                "total_properties": int(total_properties),
                "active_owners": int(active_owners),
                "active_renters": int(active_renters),
                "total_payments": int(total_payments),
            },
            "monthly_collections": monthly,
            "recent_properties": recent_properties,
        }
    except Exception as e:
        logging.exception("Failed to build public summary")
        raise HTTPException(status_code=500, detail=str(e))


@router.get("/available")
def public_available_properties(limit: int = 12):
    """
    Public endpoint to list available properties for the landing page.
    Returns recent properties with status 'available'.
    """
    try:
        conn = _get_connection()
        cur = conn.cursor()

        # Select latest available properties up to the specified limit
        cur.execute(
            f"""
            SELECT TOP {int(limit)}
                   p.id,
                   p.title,
                   p.address,
                   p.property_type,
                   p.bedrooms,
                   p.bathrooms,
                   p.area,
                   p.rent_amount,
                   p.status,
                   p.created_at,
                   u.full_name AS owner_name
            FROM properties p
            LEFT JOIN users u ON u.id = p.owner_id
            WHERE LOWER(p.status) = 'available'
            ORDER BY p.created_at DESC
            """
        )
        rows = cur.fetchall() or []
        cols = [c[0] for c in cur.description]
        items = [dict(zip(cols, row)) for row in rows]
        for it in items:
            if it.get("rent_amount") is not None:
                it["rent_amount"] = float(it["rent_amount"])  # ensure JSON serializable
            # Normalize property_type casing for display
            if it.get("property_type") and isinstance(it["property_type"], str):
                it["property_type"] = it["property_type"].title()

        return {"items": items, "count": len(items)}
    except Exception as e:
        logging.exception("Failed to fetch available properties")
        raise HTTPException(status_code=500, detail=str(e))
