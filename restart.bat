@echo off
setlocal ENABLEDELAYEDEXPANSION


REM - Stops existing backend/frontend using PIDs stored by run.py
REM - Restarts the app

set ROOT=%~dp0
cd /d "%ROOT%"

REM Set up database using merged complete database script
echo Setting up database...
REM Apply every .sql file found under backend\database in alphabetical order
echo Applying all .sql files under backend\database...
set FILECOUNT=0
for /f "delims=" %%F in ('dir /b /on "backend\database\*.sql"') do (
    set /a FILECOUNT+=1
    echo.
    echo === Applying backend\database\%%F ===
    python backend/scripts/apply_sql.py "backend/database/%%F"
    if errorlevel 1 (
        echo Failed applying backend\database\%%F
        pause
        exit /b 1
    )
)
if "%FILECOUNT%"=="0" (
    echo No .sql files found under backend\database
    pause
    exit /b 1
)

REM Wait a moment to ensure all connections are closed
timeout /t 2 > nul

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
