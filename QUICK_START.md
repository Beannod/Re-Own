# QUICK REFERENCE GUIDE

## 🚀 Starting the Application

```bash
# 1. Open PowerShell and navigate to project
cd d:\Re-Own

# 2. Activate virtual environment (if not already active)
.\.venv\Scripts\Activate.ps1

# 3. Run the application
python run.py

# 4. Application starts on:
#    Frontend: http://127.0.0.1:8080
#    Backend:  http://127.0.0.1:8000
#    API Docs: http://127.0.0.1:8000/docs
```

## 🔑 Test Login Credentials

| Role | Email | Password |
|------|-------|----------|
| Admin | admin@example.com | admin@example.com |
| Owner | owner@example.com | owner@example.com |
| Renter | renter@example.com | renter@example.com |

## 📁 Project Structure (Cleaned)

```
Re-Own/
├── backend/                  # FastAPI application
│   ├── app/
│   │   ├── main.py          # FastAPI entry point
│   │   ├── database.py      # Database connection
│   │   ├── core/            # Authentication, logging, errors
│   │   ├── routers/         # API endpoints (auth, properties, payments, etc.)
│   │   ├── schemas/         # Pydantic models
│   │   └── models/          # SQLAlchemy models (optional)
│   ├── database/
│   │   ├── create_tables.sql      # Database schema
│   │   ├── stored_procedures.sql  # All stored procedures
│   │   └── insert_test_data.sql   # Test data (250 rows)
│   ├── scripts/
│   │   └── apply_sql.py     # Database SQL applier
│   └── requirements.txt      # Python dependencies
│
├── frontend/                # Vanilla HTML/CSS/JS
│   └── public/
│       ├── index.html       # Home page
│       ├── login.html       # Login page
│       ├── owner.html       # Owner dashboard
│       ├── renter.html      # Renter dashboard
│       ├── landing.html     # Landing page
│       ├── js/              # JavaScript modules
│       └── css/             # Stylesheets
│
├── mobile-app/             # React Native app (optional)
├── docs/                   # Architecture documentation
├── logs/                   # Runtime logs (auto-created)
├── uploads/                # File storage
│
├── run.py                  # Start both frontend & backend
├── restart.bat             # Full reset (DB + App)
├── SOFTWARE_FLOW.md        # Complete documentation ⭐
├── CLEANUP_SUMMARY.md      # Files removed in cleanup
└── README.md               # Project overview
```

## 🔄 Common Tasks

### Reset Database & App
```bash
restart.bat
```

### Reset User Passwords to Email
```bash
python backend/scripts/reset_all_passwords_to_email.py
```

### Apply Database Updates
```bash
python backend/scripts/apply_sql.py backend/database/create_tables.sql
python backend/scripts/apply_sql.py backend/database/stored_procedures.sql
python backend/scripts/apply_sql.py backend/database/insert_test_data.sql
```

### View API Documentation
Open: http://127.0.0.1:8000/docs

### Check Logs
```bash
# API logs
type backend/logs/api.log

# Database logs
type backend/logs/database.log

# Error logs
type backend/logs/python_errors.log
```

## 🗂️ What Was Removed

**Total Files Removed**: 60 files
- Temporary output files (12)
- Development scripts (15)
- Database patches (5)
- SQL backups folder (16)
- Duplicate batch files (2)
- Redundant JS files (8)
- Duplicate CSS (1)
- Audit report (1)

See `CLEANUP_SUMMARY.md` for details.

## ✅ Verification Checklist

- [x] Backend starts without errors
- [x] Frontend accessible on port 8080
- [x] API responds on port 8000
- [x] Database connection working
- [x] All core files present
- [x] Test data seeded
- [x] Login functionality working

## 📖 For More Information

See **`SOFTWARE_FLOW.md`** for:
- Complete application architecture
- Detailed file descriptions
- Technology stack
- Deployment procedures
- Database schema overview

## 🛠️ Technology Stack

| Component | Technology |
|-----------|-----------|
| Backend | FastAPI 0.118.3+ |
| Server | Uvicorn |
| Database | SQL Server (SQLEXPRESS) |
| Frontend | HTML5/CSS3/JavaScript |
| Auth | JWT + pbkdf2_sha256 |
| Python | 3.12.10 |

## 📞 Troubleshooting

**Port 8000/8080 already in use?**
```bash
# Kill process on port 8000
Get-Process -Id (Get-NetTCPConnection -LocalPort 8000).OwningProcess -ErrorAction SilentlyContinue | Stop-Process -Force

# Kill process on port 8080
Get-Process -Id (Get-NetTCPConnection -LocalPort 8080).OwningProcess -ErrorAction SilentlyContinue | Stop-Process -Force
```

**Database connection issues?**
- Verify SQL Server (.\SQLEXPRESS) is running
- Check connection string in `backend/app/database.py`
- Database should be named: `property_manager_db`

**Frontend not loading?**
- Check http://127.0.0.1:8080 (note: not https)
- Check browser console for errors
- Verify backend API is accessible

---

**Last Updated**: November 19, 2025  
**Project Status**: ✅ Production Ready
