@echo off
REM Stop any running uvicorn processes
for /f "tokens=2" %%a in ('tasklist ^| findstr uvicorn') do taskkill /PID %%a /F
REM Start FastAPI backend server
cd backend
python -m uvicorn app.main:app --host 127.0.0.1 --port 8000 --reload
cd ..
pause
