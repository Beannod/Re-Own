from fastapi import APIRouter, Request
from fastapi.responses import JSONResponse
import os
import json
from backend.app.ai_error_tracker import track_error

LOG_FILE = os.path.join(os.path.dirname(__file__), '../../logs/frontend_errors.log')
router = APIRouter()


@router.post('/log_frontend_error')
async def log_frontend_error(request: Request):
    """Accept batched frontend errors and log them in structured JSON.

    Expected payloads:
    - { errors: [ { type, message, url, line, column, stack, ... }, ... ] }
    - or single error object
    """
    payload = await request.json()
    entries = []
    if isinstance(payload, dict) and 'errors' in payload and isinstance(payload['errors'], list):
        entries = payload['errors']
    elif isinstance(payload, list):
        entries = payload
    elif isinstance(payload, dict):
        entries = [payload]
    else:
        return JSONResponse({'status': 'invalid payload'}, status_code=400)

    # Ensure log directory exists
    os.makedirs(os.path.dirname(LOG_FILE), exist_ok=True)

    with open(LOG_FILE, 'a', encoding='utf-8') as f:
        for e in entries:
            timestamp = e.get('timestamp') or ''
            try:
                f.write(json.dumps({'timestamp': timestamp, **e}, ensure_ascii=False) + "\n")
            except Exception:
                f.write(str({'timestamp': timestamp, **e}) + "\n")

            # Forward to AI tracker for structured analysis when possible
            try:
                # Build a lightweight Exception to pass into track_error
                class FrontendError(Exception):
                    pass

                err = FrontendError(e.get('message', 'Frontend error'))
                track_error(err,
                            context=e.get('type', 'frontend'),
                            user_action=e.get('user_action', ''),
                            endpoint=e.get('url', ''),
                            request_data=e)
            except Exception:
                # don't let AI tracker failures break logging
                pass

    return JSONResponse({'status': 'logged', 'count': len(entries)})
