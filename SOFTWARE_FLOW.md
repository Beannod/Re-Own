# RE-OWN: Complete Software Architecture & File Structure

## Project Overview
Re-Own is a property management system with a FastAPI backend, SQL Server database, and vanilla HTML/CSS/JS frontend with an optional React Native mobile app.

---

## 1. APPLICATION FLOW

### 1.1 Request Lifecycle
```
Client Request (Browser/App)
  ↓
Frontend (HTML/CSS/JS) - ports 8080
  ↓
API Call (http://127.0.0.1:8000/api/*)
  ↓
FastAPI Router (authentication/validation)
  ↓
Database (SQL Server via pyodbc)
  ↓
Response JSON back to Frontend
  ↓
Frontend renders/updates UI
```

---

## 2. CORE BACKEND FILES (REQUIRED)

### 2.1 Entry Points
- **`run.py`** - Main application launcher
  - Starts uvicorn server (backend port 8000)
  - Starts http.server (frontend port 8080)
  - Manages process IDs for restart/shutdown

### 2.2 FastAPI Main Application
- **`backend/app/main.py`** - FastAPI app initialization
  - Global exception handling
  - Request/response logging
  - CORS middleware
  - Router includes (auth, properties, payments, etc.)
  - Mounts all API endpoints under `/api` prefix

### 2.3 Database Layer
- **`backend/app/database.py`** - Database connection & stored procedure executor
  - StoredProcedures class
  - Named pipe connection to SQL Server (SQLEXPRESS)
  - Fallback connection logic

### 2.4 Authentication & Security
- **`backend/app/core/security.py`** - JWT & password handling
  - Token creation/verification
  - Password hashing (pbkdf2_sha256)
  - Session management
- **`backend/app/core/dependencies.py`** - Dependency injection
  - get_current_user() - validates JWT
  - require_owner_access() - owner role check
  - require_renter_access() - renter role check

### 2.5 API Routers (All routers mount under `/api`)
- **`backend/app/routers/auth.py`** - `/api/auth/*`
  - Login, register, logout, user preferences
- **`backend/app/routers/properties.py`** - `/api/properties/*`
  - List, create, update, delete properties
- **`backend/app/routers/payments.py`** - `/api/payments/*`
  - List, create, update payments
- **`backend/app/routers/utilities.py`** - `/api/utilities/*`
  - Utility readings and consumption tracking
- **`backend/app/routers/reports.py`** - `/api/reports/*`
  - Occupancy, payment, consumption reports
- **`backend/app/routers/tenants.py`** - `/api/tenants/*`
  - Tenant management
- **`backend/app/routers/leases.py`** - `/api/leases/*`
  - Lease management
- **`backend/app/routers/payments.py`** - Payment operations
- **`backend/app/routers/invoices.py`** - Invoice generation
- **`backend/app/routers/maintenance.py`** - Maintenance requests
- **`backend/app/routers/public.py`** - Public endpoints (no auth required)

### 2.6 Request/Response Models (Pydantic Schemas)
- **`backend/app/schemas/user.py`** - User request/response
- **`backend/app/schemas/property.py`** - Property request/response
- **`backend/app/schemas/lease.py`** - Lease request/response
- **`backend/app/schemas/payment.py`** - Payment request/response
- **`backend/app/schemas/utility.py`** - Utility request/response
- **`backend/app/schemas/invoice.py`** - Invoice request/response
- **`backend/app/schemas/maintenance.py`** - Maintenance request/response

### 2.7 Data Models (SQLAlchemy - optional, not currently used)
- **`backend/app/models/user.py`**
- **`backend/app/models/property.py`**
- **`backend/app/models/payment.py`**
- **`backend/app/models/utility.py`**
- **`backend/app/models/owner_profile.py`**
- **`backend/app/models/renter_profile.py`**

### 2.8 Logging & Monitoring
- **`backend/app/core/logging_config.py`** - Centralized logging setup
- **`backend/app/ai_error_tracker.py`** - AI-powered error tracking & analysis
- **`backend/app/core/click_logger.py`** - Frontend click event logging
- **`backend/app/core/frontend_error_logger.py`** - Frontend error collection

### 2.9 Dependencies
- **`backend/requirements.txt`** - Python package dependencies
  - fastapi, uvicorn, pyodbc, passlib, python-jose, pydantic

---

## 3. DATABASE FILES (REQUIRED)

### 3.1 Database Schema
- **`backend/database/create_tables.sql`** - CREATE TABLE statements
  - users, properties, leases, payments, utilities, utilities_base
  - owner_profiles, renter_profiles, invoices, maintenance_requests
  - Reference tables: property_statuses, property_types, payment_types, payment_methods, payment_statuses

### 3.2 Stored Procedures
- **`backend/database/stored_procedures.sql`** - All database procedures
  - sp_GetUserById, sp_GetAllUsers
  - sp_GetAllProperties, sp_UpdateProperty
  - sp_GetPropertyOccupancyReport
  - sp_GetPaymentReport, sp_ListPayments
  - sp_GetUtilityConsumptionReport, sp_ListUtilities
  - And many more data access procedures

### 3.3 Initial Seed Data
- **`backend/database/insert_test_data.sql`** - Idempotent test data (~250 users, properties, leases)
  - Users: admin@example.com, owner@example.com, renter@example.com
  - Test properties with full details
  - Test leases, payments, utilities

### 3.4 Database Initialization Script
- **`backend/scripts/apply_sql.py`** - Applies SQL files to database
  - Used by restart.bat to set up database schema

---

## 4. FRONTEND FILES (REQUIRED)

### 4.1 HTML Pages
- **`frontend/public/index.html`** - Home/redirector page
- **`frontend/public/login.html`** - Login form
- **`frontend/public/owner.html`** - Owner dashboard
- **`frontend/public/renter.html`** - Renter dashboard  
- **`frontend/public/landing.html`** - Landing page

### 4.2 JavaScript Core
- **`frontend/public/js/api.js`** - API client (fetch wrapper with JWT token handling)
- **`frontend/public/js/auth.js`** - Authentication logic
- **`frontend/public/js/config.js`** - Configuration (API base URL, constants)
- **`frontend/public/js/util.js`** - Utility functions

### 4.3 JavaScript Features
- **`frontend/public/js/dashboard.js`** - Dashboard initialization
- **`frontend/public/js/properties.js`** - Properties page functionality
- **`frontend/public/js/payments.js`** - Payments page functionality
- **`frontend/public/js/utilities.js`** - Utilities tracking
- **`frontend/public/js/user-profile.js`** - User profile management
- **`frontend/public/js/error-collector.js`** - Frontend error collection & reporting
- **`frontend/public/js/linking.js`** - Page linkage/navigation

### 4.4 Stylesheets
- **`frontend/public/css/style.css`** - Main stylesheet
- **`frontend/public/css/auth.css`** - Login/auth page styles
- **`frontend/public/css/owner.css`** - Owner dashboard styles
- **`frontend/public/css/renter.css`** - Renter dashboard styles
- **`frontend/public/css/landing.css`** - Landing page styles
- **`frontend/public/css/index.css`** - Home page styles

---

## 5. STARTUP & EXECUTION

### 5.1 How to Run
```bash
# Terminal 1: Start backend and frontend
python run.py

# App will start on:
# - Backend API: http://127.0.0.1:8000
# - Frontend: http://127.0.0.1:8080
# - API Docs: http://127.0.0.1:8000/docs
```

### 5.2 Restart/Reset Batch Files
- **`restart.bat`** - Full application reset (DB + App)
  - Applies SQL schema
  - Seeds test data
  - Resets passwords
  - Restarts application

---

## 6. CONFIGURATION

### 6.1 Environment
- **Python**: 3.12.10
- **Virtual Environment**: `.venv/`
- **Database**: SQL Server (.\SQLEXPRESS)
- **Connection**: Named pipe (np:\\.\pipe\MSSQL$SQLEXPRESS\sql\query)
- **Dev Flag**: BYPASS_DB_SESSION=true (in run.py)

### 6.2 Ports
- **Backend**: 8000
- **Frontend**: 8080

---

## 7. OPTIONAL/FUTURE COMPONENTS

### 7.1 Mobile App (React Native)
- **`mobile-app/App.tsx`** - Main mobile app entry
- **`mobile-app/src/screens/*`** - Login, Dashboard, Properties, Payments screens
- **`mobile-app/src/services/ApiService.ts`** - Backend API calls
- **`mobile-app/src/utils/AuthContext.tsx`** - Authentication state management
- Status: Framework setup complete, not fully integrated with backend

---

## 8. CLEANUP STATUS

The repository has already been pruned of the previously listed duplicate or deprecated frontend files (extra JS/CSS variants). No obsolete maintenance or patch scripts remain beyond the minimal operational set (`run.py`, `restart.bat`, `backend/scripts/apply_sql.py`). Runtime log and error JSON files (e.g. `ai_error_log.json`, `sql_error_log.json`) are retained intentionally for diagnostics and should not be deleted manually.

If new one-off migration or probe scripts are added in the future, document and remove them after use to keep the codebase lean. This section replaces the former exhaustive candidate list.

Summary:
- Duplicate frontend helper scripts: Not present
- Redundant stylesheets (`index.css`): Not present
- Legacy database patch/test SQL: Not present
- One-off fix scripts (e.g. deposit column): Removed
- Active required scripts: `apply_sql.py` only

Action Guidance:
- Keep error logs and uploads directories (auto-generated)
- Add new cleanup notes here only when something is slated for removal
- Prefer stored procedures + documented migrations over ad-hoc Python/SQL patch files

This lean status supports easier onboarding and reduces noise in reviews.

---

## 9. RECOMMENDED PROJECT STRUCTURE (CLEANED)

```
Re-Own/
├── run.py                           # REQUIRED: Start app
├── restart.bat                      # REQUIRED: Reset app
├── README.md                        # Documentation
├── backend/
│   ├── requirements.txt             # REQUIRED: Dependencies
│   ├── app/
│   │   ├── main.py                  # REQUIRED: FastAPI app
│   │   ├── database.py              # REQUIRED: DB connection
│   │   ├── ai_error_tracker.py      # Error tracking
│   │   ├── core/
│   │   │   ├── security.py          # REQUIRED: Auth/JWT
│   │   │   ├── dependencies.py      # REQUIRED: Dep injection
│   │   │   ├── logging_config.py    # Logging setup
│   │   │   ├── click_logger.py      # Click tracking
│   │   │   └── frontend_error_logger.py # Error collection
│   │   ├── routers/                 # REQUIRED: All routers
│   │   │   ├── auth.py
│   │   │   ├── properties.py
│   │   │   ├── payments.py
│   │   │   ├── utilities.py
│   │   │   ├── reports.py
│   │   │   ├── tenants.py
│   │   │   ├── leases.py
│   │   │   ├── invoices.py
│   │   │   ├── maintenance.py
│   │   │   └── public.py
│   │   ├── schemas/                 # REQUIRED: Data schemas
│   │   ├── models/                  # Optional: SQLAlchemy models
│   │   └── __init__.py
│   ├── database/
│   │   ├── create_tables.sql        # REQUIRED: Schema
│   │   ├── stored_procedures.sql    # REQUIRED: Procedures
│   │   └── insert_test_data.sql     # REQUIRED: Seed data
│   ├── scripts/
│   │   └── apply_sql.py             # REQUIRED: SQL applier
│   ├── logs/                        # Runtime logs (auto-created)
│   ├── uploads/                     # File uploads (auto-created)
│   └── __init__.py
├── frontend/
│   └── public/
│       ├── index.html               # REQUIRED: Home
│       ├── login.html               # REQUIRED: Login
│       ├── owner.html               # REQUIRED: Owner dashboard
│       ├── renter.html              # REQUIRED: Renter dashboard
│       ├── landing.html             # Landing page
│       ├── js/
│       │   ├── api.js               # REQUIRED: API client
│       │   ├── auth.js              # REQUIRED: Auth logic
│       │   ├── config.js            # REQUIRED: Config
│       │   ├── util.js              # REQUIRED: Utilities
│       │   ├── dashboard.js         # Dashboard logic
│       │   ├── properties.js        # Properties page
│       │   ├── payments.js          # Payments page
│       │   ├── utilities.js         # Utilities tracking
│       │   ├── user-profile.js      # Profile management
│       │   ├── error-collector.js   # Error collection
│       │   └── linking.js           # Navigation
│       └── css/
│           ├── style.css            # REQUIRED: Main styles
│           ├── auth.css             # Auth styles
│           ├── owner.css            # Owner styles
│           ├── renter.css           # Renter styles
│           └── landing.css          # Landing styles
├── docs/                            # Documentation
├── logs/                            # Runtime logs
├── uploads/                         # File storage
├── .venv/                           # Virtual environment
└── .gitignore
```

---

## 10. DEPLOYMENT CHECKLIST

- [ ] Python 3.12+ installed
- [ ] Virtual environment (.venv) activated
- [ ] `backend/requirements.txt` installed
- [ ] SQL Server (SQLEXPRESS) running
- [ ] Database schema created (create_tables.sql)
- [ ] Stored procedures loaded (stored_procedures.sql)
- [ ] Test data seeded (insert_test_data.sql)
- [ ] `run.py` executable
- [ ] Frontend assets in `frontend/public/`
- [ ] Ports 8000 & 8080 available
- [ ] BYPASS_DB_SESSION set (development mode)

---

## 11. QUICK START

```bash
# 1. Activate virtual environment
.\\.venv\\Scripts\\Activate.ps1

# 2. Start application (starts both backend and frontend)
python run.py

# 3. Open browser
# Frontend:   http://127.0.0.1:8080
# API Docs:   http://127.0.0.1:8000/docs
# API:        http://127.0.0.1:8000/api/*

# 4. Login
# Admin:   admin@example.com / admin@example.com
# Owner:   owner@example.com / owner@example.com
# Renter:  renter@example.com / renter@example.com
```

---

## 12. TECHNOLOGY STACK

| Component | Technology | Version |
|-----------|-----------|---------|
| Backend Framework | FastAPI | 0.118.3+ |
| ASGI Server | Uvicorn | 0.37.0+ |
| Database | SQL Server | Express |
| ORM | pyodbc | (raw SQL + stored procedures) |
| Auth | JWT (python-jose) | - |
| Password Hash | pbkdf2_sha256 (passlib) | - |
| Frontend | HTML5/CSS/JS | Vanilla (no framework) |
| Mobile (Optional) | React Native | - |
| Python | CPython | 3.12.10 |

---

**Document Version**: 1.0  
**Last Updated**: November 19, 2025  
**Status**: Production Ready
