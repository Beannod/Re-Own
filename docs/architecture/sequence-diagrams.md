# Sequence Diagrams

This document outlines key end-to-end flows across the system.

## 1) Authentication: Login → Session → Me → Logout

```mermaid
sequenceDiagram
  autonumber
  participant U as User (Browser)
  participant FE as Frontend (JS)
  participant API as FastAPI Backend
  participant DB as SQL Server

  U->>FE: Enter email/password
  FE->>API: POST /api/auth/login {email, password}
  API->>DB: Validate user (sp_GetUserByEmail)
  DB-->>API: user + password hash
  API->>API: Verify password, create JWT (sid)
  API->>DB: create_session(sid, user_id)
  DB-->>API: OK (expires_at)
  API-->>FE: 200 {access_token, session_id}
  FE->>FE: Store token + sessionId
  U->>FE: Navigate pages
  FE->>API: GET /api/auth/me (Authorization: Bearer ...)
  API->>DB: validate session (sid) + touch_session
  DB-->>API: OK
  API-->>FE: 200 {user, role, session_id}
  U->>FE: Click Logout
  FE->>API: POST /api/auth/logout (Authorization: Bearer ...)
  API->>DB: revoke_session(sid)
  DB-->>API: OK
  API-->>FE: 200 {ok}
```

## 2) Lease → Invoice Generation

```mermaid
sequenceDiagram
  autonumber
  participant OW as Owner
  participant FE as Frontend (Owner UI)
  participant API as Backend
  participant DB as SQL Server

  OW->>FE: Create/Update Lease
  FE->>API: POST /api/leases {...}
  API->>DB: sp_CreateOrUpdateLease
  DB-->>API: LeaseId
  Note over API: Nightly/Batched
  API->>DB: sp_GenerateInvoices(LeaseId or Period)
  DB-->>API: Invoice(s)
  API-->>FE: 201/200 {invoices}
```

## 3) Payment Allocation to Transactions

```mermaid
sequenceDiagram
  autonumber
  participant RN as Renter
  participant FE as Frontend (Renter UI)
  participant API as Backend
  participant PG as Payment Gateway
  participant DB as SQL Server

  RN->>FE: Pay invoice
  FE->>API: POST /api/payments {invoiceId, amount, method}
  API->>PG: Create charge (if online)
  PG-->>API: Charge success
  API->>DB: sp_RecordPayment(invoiceId, amount, method)
  DB->>DB: Allocate to line-level transactions (due date, priority)
  DB-->>API: PaymentId + allocations
  API-->>FE: 200 {receipt, allocations}
```

## 4) Utility Meter Reading → Billing

```mermaid
sequenceDiagram
  autonumber
  participant ST as Staff/Owner
  participant FE as Frontend (Owner UI)
  participant API as Backend
  participant DB as SQL Server

  ST->>FE: Enter monthly meter readings
  FE->>API: POST /api/utilities/readings {unitId, meterId, period, reading}
  API->>DB: sp_UpsertMeterReading
  DB-->>API: OK
  Note over API: Billing run (monthly)
  API->>DB: sp_GenerateUtilityCharges(period)
  DB-->>API: Charges line items
  API-->>FE: 200 {charges}
```

## 5) Maintenance Request Lifecycle

```mermaid
sequenceDiagram
  autonumber
  participant RN as Renter
  participant FE as Frontend (Renter UI)
  participant API as Backend
  participant DB as SQL Server
  participant VN as Vendor/Technician

  RN->>FE: Create request (issue, photo)
  FE->>API: POST /api/maintenance {unitId, details}
  API->>DB: sp_CreateMaintenanceRequest
  DB-->>API: RequestId
  API-->>FE: 201 {RequestId}
  API->>VN: Notify via email/SMS
  VN->>API: Update status (accepted/scheduled)
  API->>DB: sp_UpdateMaintenanceStatus
  DB-->>API: OK
  API-->>FE: Status stream/refresh
```

## 6) Session Expiry and Sliding Window

```mermaid
sequenceDiagram
  autonumber
  participant FE as Frontend
  participant API as Backend
  participant DB as SQL Server

  loop On each authorized request
    FE->>API: GET /api/...
    API->>DB: Validate sid and expiry
    DB-->>API: OK; update last_seen, extend expires_at
    API-->>FE: 200 response
  end
  Note over API,DB: Revocation or expiry returns 401/403
```

## Notes
- The repo currently uses FastAPI + SQL Server + pyodbc; adjust SP names to fit your DB naming.
- If you want, we can add sequence diagrams for: Owner onboarding, Unit assignment, Reporting/Exports, Notification digests.
