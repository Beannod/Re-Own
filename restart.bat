@echo off
setlocal ENABLEDELAYEDEXPANSION


REM - Stops existing backend/frontend using PIDs stored by run.py
REM - Restarts the app

set ROOT=%~dp0
cd /d "%ROOT%"

REM Initialize database
echo Initializing database...
python backend/scripts/apply_sql.py backend/database/init_database.sql
if errorlevel 1 (
    echo Failed to initialize database
    pause
    exit /b 1
)

REM Set up database schema
echo Creating database schema...
python backend/scripts/apply_sql.py backend/database/complete_database.sql
if errorlevel 1 (
    echo Failed to create database
    pause
    exit /b 1
)

echo Setting up reference tables...
python backend/scripts/apply_sql.py backend/database/reference_tables.sql
if errorlevel 1 (
    echo Failed to create reference tables
    pause
    exit /b 1
)

echo Creating reference procedures...
python backend/scripts/apply_sql.py backend/database/reference_procedures.sql
if errorlevel 1 (
    echo Failed to create reference procedures
    pause
    exit /b 1
)

REM Wait a moment to ensure all connections are closed
timeout /t 2 > nul

REM Apply SQL files in specific order
echo Applying payment procedures...
python backend/scripts/apply_sql.py backend/database/payment_procedures.sql
if errorlevel 1 (
    echo Note: Payment procedures may already exist in complete_database.sql, continuing...
)

echo Applying payment report procedures...
python backend/scripts/apply_sql.py backend/database/payment_report_procedure.sql
if errorlevel 1 (
    echo Note: Payment report procedures may already exist in complete_database.sql, continuing...
)

echo Applying occupancy report...
python backend/scripts/apply_sql.py backend/database/occupancy_report.sql
if errorlevel 1 (
    echo Note: Occupancy report procedures may already exist in complete_database.sql, continuing...
)

echo Applying payment data updates...
python backend/scripts/apply_sql.py backend/database/update_payment_data.sql
if errorlevel 1 (
    echo Note: Payment data updates failed, you may need to check for duplicate entries
    pause
    exit /b 1
)

echo Fixing property status values...
python backend/scripts/apply_sql.py backend/database/fix_property_status.sql
if errorlevel 1 (
    echo Note: Failed to fix property status values
    pause
    exit /b 1
)

echo Resetting all user passwords to their email addresses...
python backend/scripts/reset_all_passwords_to_email.py
if errorlevel 1 (
    echo Failed to reset passwords
    pause
    exit /b 1
)

set PIDFILE=reown_pids.json

if exist "%PIDFILE%" (
    REM Use PowerShell to parse JSON and extract PIDs
    for /f %%B in ('powershell -NoProfile -Command "Get-Content '%PIDFILE%' | ConvertFrom-Json | Select-Object -ExpandProperty backend_pid"') do set BACKEND_PID=%%B
    for /f %%C in ('powershell -NoProfile -Command "Get-Content '%PIDFILE%' | ConvertFrom-Json | Select-Object -ExpandProperty frontend_pid"') do set FRONTEND_PID=%%C

    if defined BACKEND_PID (
        echo Stopping backend PID %BACKEND_PID%...
        taskkill /PID %BACKEND_PID% /T /F >NUL 2>&1
    )
    if defined FRONTEND_PID (
        echo Stopping frontend PID %FRONTEND_PID%...
        taskkill /PID %FRONTEND_PID% /T /F >NUL 2>&1
    )
    del "%PIDFILE%" >NUL 2>&1
) else (
    echo No PID file found. Attempting to stop by process names...
    taskkill /IM python.exe /F /T >NUL 2>&1
)

REM Reset all user passwords to their email addresses
echo Resetting user passwords...
python backend/scripts/reset_all_passwords_to_email.py
if errorlevel 1 (
    echo Failed to reset passwords
    pause
    exit /b 1
)

REM Start the app again
echo Starting app...
start "Re-Own Backend" cmd /c "python run.py"

echo Restart command issued. You can close this window.
endlocal
