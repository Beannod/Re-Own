@echo off
setlocal ENABLEDELAYEDEXPANSION

REM Restart script for Re-Own dev servers (Windows)
REM - Applies SQL files
REM - Stops existing backend/frontend using PIDs stored by run.py
REM - Restarts the app

set ROOT=%~dp0
cd /d "%ROOT%"

REM Drop and recreate database
echo Applying complete database reset...
python backend/scripts/apply_sql.py backend/database/complete_database.sql
if errorlevel 1 (
    echo Failed to apply database schema
    pause
    exit /b 1
)

REM Apply test data if exists
if exist backend/database/test_data.sql (
    echo Applying test data...
    python backend/scripts/apply_sql.py backend/database/test_data.sql
    if errorlevel 1 (
        echo Failed to apply test data
        pause
        exit /b 1
    )
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

REM Start the app again
echo Starting app...
start "Re-Own Backend" cmd /c "python run.py"

echo Restart command issued. You can close this window.
endlocal
