# Re-Own Property Management

A property management system with FastAPI backend and a static HTML/JS frontend.

## Quick Start

- Backend: see `backend/requirements.txt`, run the app via `python run.py`
- Frontend: open `frontend/public/landing.html` in a browser (or serve statically)

## Docs

- Architecture Overview: [docs/architecture/system-architecture.md](docs/architecture/system-architecture.md)
- Sequence Diagrams: [docs/architecture/sequence-diagrams.md](docs/architecture/sequence-diagrams.md)

## Notes

- Auth uses JWT + DB-backed sessions (revocation + sliding expiry)
- Cross-page deep linking supported via query params (tenantId, propertyId, unitId, leaseId, invoiceId, transactionId, maintenanceId, meterId)
- Owner/Renter pages include table of contents and section anchors
--
  $pbkdf2-sha256$29000$8F4LQch5r9X6PwfA2BvjHA$oGJZmKp.BeWQp.mkJ62JPg2YQubHnl.CV2ieAHUki0A