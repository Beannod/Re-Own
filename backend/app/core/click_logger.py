from fastapi import APIRouter, Request
from fastapi.responses import JSONResponse
import json
from datetime import datetime
import os

router = APIRouter()
LOG_FILE = os.path.join(os.path.dirname(__file__), '../../logs/click_events.log')

@router.post('/log_click')
async def log_click(request: Request):
    data = await request.json()
    log_entry = {
        'action': data.get('action'),
        'timestamp': data.get('timestamp', datetime.utcnow().isoformat()),
        'user': data.get('user')
    }
    try:
        with open(LOG_FILE, 'a', encoding='utf-8') as f:
            f.write(json.dumps(log_entry) + '\n')
        return JSONResponse({'status': 'ok'})
    except Exception as e:
        return JSONResponse({'status': 'error', 'detail': str(e)}, status_code=500)
