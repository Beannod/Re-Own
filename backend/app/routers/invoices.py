from fastapi import APIRouter, Query
from fastapi.responses import JSONResponse
from typing import Optional
from ..schemas import invoice as invoice_schema

router = APIRouter(
    prefix="/invoices",
    tags=["Invoices"]
)


@router.post("/generate", response_model=invoice_schema.Invoice)
def generate_invoices(lease_id: Optional[int] = Query(default=None), period: Optional[str] = Query(default=None)):
    """Planned: Generate invoices for a lease or period (sp_GenerateInvoices)."""
    return JSONResponse(status_code=501, content={
        "detail": "Not implemented",
        "code": "NOT_IMPLEMENTED",
        "hint": "Generate invoices via sp_GenerateInvoices for given lease_id or period.",
        "params": {"lease_id": lease_id, "period": period}
    })


@router.get("/{invoice_id}", response_model=invoice_schema.Invoice)
def get_invoice(invoice_id: int):
    """Planned: Get invoice by ID (sp_GetInvoice)."""
    return JSONResponse(status_code=501, content={
        "detail": "Not implemented",
        "code": "NOT_IMPLEMENTED",
        "hint": f"Fetch invoice details via sp_GetInvoice for InvoiceId={invoice_id}."
    })


@router.get("/{invoice_id}/transactions", response_model=list[invoice_schema.Transaction])
def get_invoice_transactions(invoice_id: int):
    """Planned: Get line-item transactions for invoice (sp_GetInvoiceTransactions)."""
    return JSONResponse(status_code=501, content={
        "detail": "Not implemented",
        "code": "NOT_IMPLEMENTED",
        "hint": f"Fetch transactions via sp_GetInvoiceTransactions for InvoiceId={invoice_id}."
    })
