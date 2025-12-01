from fastapi import APIRouter, Request, HTTPException
from fastapi.responses import JSONResponse
from pathlib import Path
import json
from datetime import datetime
from ..ai_error_tracker import track_error

router = APIRouter(prefix="/logs", tags=["Logs"])

_LOG_PATH = Path(__file__).parent.parent.parent / "logs" / "frontend_errors.log"


@router.post("/error")
async def log_single_error(request: Request):
    """Accept a single frontend error entry from `error-logger.js`.

    The payload is an arbitrary JSON object produced by the client. We append it
    as a line-delimited JSON entry to `frontend_errors.log` and forward a lightweight
    representation into the AI error tracker for correlation. Always returns 200
    unless payload is not valid JSON.
    """
    try:
        data = await request.json()
    except Exception as e:
        raise HTTPException(status_code=400, detail=f"Invalid JSON payload: {e}")

    # Normalized entry
    entry = {
        "received_at": datetime.utcnow().isoformat(),
        **(data if isinstance(data, dict) else {"raw": data})
    }

    try:
        _LOG_PATH.parent.mkdir(exist_ok=True)
        with open(_LOG_PATH, "a", encoding="utf-8") as f:
            f.write(json.dumps(entry, ensure_ascii=False) + "\n")
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to persist log: {e}")

    # Forward minimal info to AI tracker (best effort, never fails request)
    try:
        msg = entry.get("message") or entry.get("title") or "Frontend error"
        class FrontendClientError(Exception):
            pass
        track_error(
            error=FrontendClientError(msg),
            context=entry.get("title", "frontend"),
            user_action=entry.get("title", "frontend"),
            endpoint="/api/logs/error",
            request_data=entry,
            severity=entry.get("level", "INFO")
        )
    except Exception:
        pass

    return JSONResponse({"status": "logged"}, status_code=200)
