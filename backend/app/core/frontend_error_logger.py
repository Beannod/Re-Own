from fastapi import APIRouter, Request
from fastapi.responses import JSONResponse
import os

LOG_FILE = os.path.join(os.path.dirname(__file__), '../../logs/frontend_errors.log')
router = APIRouter()

@router.post('/log_frontend_error')
async def log_frontend_error(request: Request):
    data = await request.json()
    error_message = data.get('message', 'Unknown error')
    error_url = data.get('url', '')
    error_line = data.get('line', '')
    error_column = data.get('column', '')
    error_stack = data.get('stack', '')
    with open(LOG_FILE, 'a', encoding='utf-8') as f:
        f.write(f"ERROR: {error_message}\nURL: {error_url}\nLine: {error_line}, Column: {error_column}\nStack: {error_stack}\n---\n")
    return JSONResponse({'status': 'logged'})
