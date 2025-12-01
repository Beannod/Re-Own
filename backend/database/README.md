# Database Setup (Re-own)

This folder contains the minimal schema and stored procedures required for registration & login.

## Files
- `schema_reown.sql`: Creates the `[Re-own]` database and the core tables: `users`, `sessions`, `owner_profiles`, `renter_profiles`, plus a minimal `properties` table.
- `stored_procedures_core.sql`: Minimal SPs used by the backend during register/login and profile creation.

## Apply Order
1. Schema
```powershell
python backend\scripts\apply_sql.py backend\database\schema_reown.sql
```
2. Stored Procedures
```powershell
python backend\scripts\apply_sql.py backend\database\stored_procedures_core.sql
```

## Environment
Set DB name (optional, default is `Re-own` configured in code):
```powershell
$env:DB_NAME='Re-own'
```

Then run the app:
```powershell
python run.py
```
