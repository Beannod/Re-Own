@echo off
REM Start FastAPI backend server only
cd backend
python -m uvicorn app.main:app --host 127.0.0.1 --port 8000 --reload
cd ..
pause
