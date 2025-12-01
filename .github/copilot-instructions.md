# Re-Own: AI Coding Agent Instructions

Concise, project-specific guidance for AI assistants working in this repo. Focus on actual implemented patterns (FastAPI + SQL Server + static frontend + optional React Native mobile app).

## Core Architecture
- One launcher: `run.py` starts FastAPI (port 8000) and a Python `http.server` for static frontend (port 8080).
- API mounted under `/api` via `backend/app/main.py` using an `APIRouter` (`api_router.include_router(...)`). New routers go in `backend/app/routers/` then must be included in `main.py` before deployment.
- Database access is via stored procedures in `backend/database/stored_procedures.sql` using `StoredProcedures.execute_sp()`; graceful fallback to direct SQL exists in `database.py` for missing SPs (do not rely on fallback in new code—add proper SPs instead).
- Session + auth: JWT with `sid` (session id) claim; DB session validation unless `BYPASS_DB_SESSION=true` (set in `run.py` for dev hot reload). Use `get_current_user()` / role helpers in `core/dependencies.py` for protected endpoints.
- Logging: Structured multi-file logging via `core/logging_config.py`; AI error tracking using `ai_error_tracker.py`. Errors produce `ai_error_log.json` / `sql_error_log.json`—never hand-edit these.
- Frontend: vanilla HTML/JS served statically; deep-link navigation via query params mapping to anchors in `owner.html` / `renter.html` (see `system-architecture.md`). Keep new query params normalized (camelCase) and document anchor mapping.

## Run & Common Workflows
```powershell
# Start backend + frontend
python run.py
# Apply schema / procedures / seed data
python backend/scripts/apply_sql.py backend/database/create_tables.sql
python backend/scripts/apply_sql.py backend/database/stored_procedures.sql
python backend/scripts/apply_sql.py backend/database/insert_test_data.sql
# Full reset (DB + seeds + passwords)
restart.bat
```
Test users: admin/owner/renter `email == password` (see `QUICK_START.md`).

## Conventions & Patterns
- Routers: Define `router = APIRouter(prefix="/resource", tags=["resource"])`; return dict/typed Pydantic models from `schemas/`. Include new router inside the `api_router` section in `main.py` (not at root level unless intentionally global like click/error loggers).
- Error responses: Use `HTTPException(..., headers={"X-Error-Code": CODE})` with codes consistent with existing (`INVALID_TOKEN`, `SESSION_EXPIRED`, etc.). Reuse patterns in `core/security.py` and `dependencies.py`.
- Stored procedure calls: Always parameterize (let `execute_sp` build placeholder string). Add new procedures with `CREATE OR ALTER` form, then re-run apply script.
- Fallback logic in `database.py` (e.g., `_direct_insert_property`) exists for resilience—do not duplicate; prefer adding/repairing SPs.
- Session sliding window handled by `touch_session` inside security verification; avoid manual expiry updates.
- Logging: Use category-specific logger via `get_logger('api'|'security'|...)`; for exceptions use `log_exception(logger, msg, exc)`; do not reconfigure logging in new modules.
- Frontend API calls: Mirror existing pattern in `frontend/public/js/api.js` (fetch wrapper with token) and keep endpoint paths under `/api/*`.
- Deep-link params: Maintain normalization list in `system-architecture.md`; if adding new anchor, update both HTML and architecture doc.
- Mobile app (optional): Points to same backend (`API_BASE_URL` should be `http://127.0.0.1:8000/api`). Keep parity with web auth flow.

## Adding Features (Example Flow)
1. Create stored procedure in `stored_procedures.sql` (use `CREATE OR ALTER` + deterministic column set).
2. Apply it: run apply script.
3. Add Pydantic schema in `backend/app/schemas/<entity>.py` if needed.
4. Implement router in `backend/app/routers/<entity>.py` using dependencies for auth/role.
5. Include router in `main.py` via `api_router.include_router(<entity>_router.router)`.
6. Add frontend JS module or extend existing (`properties.js`, etc.) ensuring token handling via `api.js`.
7. Update docs (`SOFTWARE_FLOW.md` or architecture docs) only for structural changes; keep this file concise.

## Do / Avoid
- DO reuse `StoredProcedures.execute_sp` & add SP; AVOID raw inline SQL unless implementing a sanctioned fallback.
- DO attach `X-Error-Code` for auth/permission failures; AVOID ad-hoc status messages.
- DO centralize new logs via `get_logger`; AVOID creating new ad-hoc log directories/files.
- DO keep responses snake_case or existing field casing; AVOID introducing inconsistent naming.

## Quick Reference
Ports: Backend 8000 / Frontend 8080. Root health: `/health`. API docs: `/docs`. Uploads served at `/uploads` (auto-created).

## Clarification Needed?
Request feedback: specify any missing domain rules (billing, reporting calculations) or deeper test strategy you want documented.
