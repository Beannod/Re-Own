from fastapi import FastAPI, HTTPException, Request, APIRouter
from fastapi.staticfiles import StaticFiles
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse
import traceback
import logging
from datetime import datetime
import json
from pathlib import Path
import os
from .ai_error_tracker import track_error, ai_tracker
from .database import StoredProcedures
from .routers import auth as auth_router
from .routers import properties as properties_router
from .routers import payments as payments_router
from .routers import tenants as tenants_router
from .routers import utilities as utilities_router
from .routers import public as public_router
from .routers import leases as leases_router
from .routers import invoices as invoices_router
from .routers import maintenance as maintenance_router
from .routers import reports as reports_router

# Configure logging first
# Create logs directory if it doesn't exist
log_dir = Path(__file__).parent.parent.parent / 'logs'
log_dir.mkdir(exist_ok=True)

# Set up file handlers for different log files
debug_handler = logging.FileHandler(log_dir / 'debug.log')
python_error_handler = logging.FileHandler(log_dir / 'python_errors.log')
console_handler = logging.StreamHandler()

# Set format for logs
log_format = logging.Formatter('%(asctime)s - %(name)s - %(levelname)s - %(message)s')
debug_handler.setFormatter(log_format)
python_error_handler.setFormatter(log_format)
console_handler.setFormatter(log_format)

# Configure logging levels
debug_handler.setLevel(logging.DEBUG)
python_error_handler.setLevel(logging.ERROR)  # Only capture errors and above
console_handler.setLevel(logging.INFO)

# Configure root logger
logging.basicConfig(
    level=logging.DEBUG,
    handlers=[debug_handler, python_error_handler, console_handler]
)

logger = logging.getLogger(__name__)

# Function to clear all logs
def clear_logs():
    # Clear error tracking files (JSON)
    error_files = ['ai_error_log.json', 'sql_error_log.json']
    root_dir = Path(__file__).parent.parent.parent
    
    # Clear JSON error logs
    for file_name in error_files:
        file_path = root_dir / file_name
        if file_path.exists():
            try:
                empty_log = {"errors": []}
                with open(file_path, 'w') as f:
                    json.dump(empty_log, f, indent=2)
                logger.info(f"Cleared error log file: {file_name}")
            except Exception as e:
                logger.error(f"Failed to clear error log {file_name}: {e}")
    
    # Clear text log files
    log_files = ['debug.log', 'python_errors.log']
    for file_name in log_files:
        file_path = log_dir / file_name
        try:
            # Create or clear the file
            with open(file_path, 'w') as f:
                f.write(f"Log file cleared at {datetime.now().isoformat()}\n")
            logger.info(f"Cleared log file: {file_name}")
        except Exception as e:
            logger.error(f"Failed to clear log {file_name}: {e}")

# Clear all logs on startup
clear_logs()

app = FastAPI(title="Property Management System API", debug=True)

# Enable CORS
app.add_middleware(
    CORSMiddleware,
    allow_origins=["http://127.0.0.1:8080", "http://localhost:8080"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Global exception handler with AI error tracking
@app.exception_handler(Exception)
async def global_exception_handler(request: Request, exc: Exception):
    # Log the error with full traceback
    logger.error(
        f"Unhandled exception on {request.method} {request.url}",
        exc_info=exc,
        extra={
            "request_path": str(request.url),
            "method": request.method,
            "client_host": request.client.host if request.client else "unknown",
            "headers": dict(request.headers)
        }
    )
    
    # Track error for AI analysis
    error_data = track_error(
        error=exc,
        context=f"Unhandled exception in {request.method} {request.url.path}",
        user_action="API request",
        endpoint=str(request.url.path),
        request_data={
            "method": request.method,
            "url": str(request.url),
            "headers": dict(request.headers)
        },
        severity="CRITICAL"
    )
    
    error_details = {
        "error": str(exc),
        "type": type(exc).__name__,
        "traceback": traceback.format_exc(),
        "path": str(request.url),
        "method": request.method,
        "timestamp": datetime.now().isoformat(),
        "ai_tracking_id": error_data.get("timestamp")  # Reference to AI log
    }
    
    logger.error(f"Unhandled exception: {error_details}")
    
    return JSONResponse(
        status_code=500,
        content={
            "detail": f"Internal server error: {str(exc)}",
            "debug_info": error_details,
            "ai_suggestions": error_data.get("suggested_fixes", [])
        }
    )

# Request logging middleware with AI error context
@app.middleware("http")
async def log_requests(request: Request, call_next):
    start_time = datetime.now()
    logger.info(f"Request started: {request.method} {request.url}")
    
    try:
        response = await call_next(request)
        process_time = (datetime.now() - start_time).total_seconds()
        logger.info(f"Request completed: {request.method} {request.url} - {response.status_code} in {process_time:.3f}s")
        return response
    except Exception as e:
        # Track middleware errors
        track_error(
            error=e,
            context=f"Request middleware error for {request.method} {request.url.path}",
            user_action="Processing HTTP request",
            endpoint=str(request.url.path),
            severity="ERROR"
        )
        raise

# Configure CORS
app.add_middleware(
    CORSMiddleware,
    allow_origins=["http://127.0.0.1:8080", "http://localhost:8080"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
    expose_headers=["X-Error-Code"]
)

@app.get("/")
async def root():
    logger.info("Root endpoint accessed")
    return {"message": "Welcome to Property Management System API"}

@app.get("/health")
async def health():
    return {"status": "ok"}

@app.get("/debug/errors")
async def get_error_summary():
    """Get AI error analysis summary"""
    try:
        summary = ai_tracker.get_error_summary()
        return summary
    except Exception as e:
        track_error(
            error=e,
            context="Fetching error summary for debugging",
            user_action="Admin checking error logs",
            endpoint="/debug/errors"
        )
        raise HTTPException(status_code=500, detail=f"Failed to get error summary: {str(e)}")
@app.get("/debug/sql-errors")
async def get_sql_errors():
    try:
        log_path = Path(os.getcwd()) / "sql_error_log.json"
        if not log_path.exists():
            return {"errors": []}
        with open(log_path, 'r', encoding='utf-8') as f:
            data = json.load(f)
        # Return last 50 for brevity
        errors = data.get("errors", [])[-50:]
        return {"count": len(errors), "errors": errors}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@app.get("/debug/db-connection")
async def db_connection_check():
    try:
        info = StoredProcedures.test_connection()
        if info.get("status") != "ok":
            raise HTTPException(status_code=500, detail=info)
        return info
    except HTTPException:
        raise
    except Exception as e:
        track_error(
            error=e,
            context="Database connection debug endpoint",
            user_action="Check DB connectivity",
            endpoint="/debug/db-connection",
            severity="ERROR"
        )
        raise HTTPException(status_code=500, detail=str(e))

@app.get("/debug/test-error")
async def test_error():
    """Endpoint to test AI error tracking"""
    try:
        # Intentionally cause different types of errors for testing
        import random
        error_type = random.choice(['attribute', 'value', 'key', 'type'])
        
        if error_type == 'attribute':
            obj = None
            obj.some_attribute  # AttributeError
        elif error_type == 'value':
            int("not_a_number")  # ValueError
        elif error_type == 'key':
            data = {}
            data['nonexistent_key']  # KeyError
        else:
            "string" + 123  # TypeError
            
    except Exception as e:
        track_error(
            error=e,
            context="Testing AI error tracking system",
            user_action="Admin testing error handling",
            endpoint="/debug/test-error",
            severity="INFO"
        )
        raise HTTPException(status_code=500, detail=f"Test error generated: {str(e)}")

"""
Mount versioned API routers under /api
"""
api_router = APIRouter(prefix="/api")

# Mount all routers under the /api router
api_router.include_router(auth_router.router)
api_router.include_router(properties_router.router)
api_router.include_router(payments_router.router)
api_router.include_router(tenants_router.router)
api_router.include_router(utilities_router.router)
api_router.include_router(public_router.router)
api_router.include_router(leases_router.router)
api_router.include_router(invoices_router.router)
api_router.include_router(maintenance_router.router)
api_router.include_router(reports_router.router)

# Mount the API router
app.include_router(api_router)

# Serve uploaded files
import os
uploads_path = os.path.join(os.getcwd(), "uploads")
os.makedirs(uploads_path, exist_ok=True)
app.mount("/uploads", StaticFiles(directory=uploads_path), name="uploads")

if __name__ == "__main__":
    import uvicorn
    uvicorn.run("app.main:app", host="127.0.0.1", port=8000, reload=True)
