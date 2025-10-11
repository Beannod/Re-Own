from datetime import datetime, timedelta
from typing import Optional
from jose import JWTError, jwt
from passlib.context import CryptContext
from fastapi import HTTPException, status
import uuid
import pyodbc
from ..database import StoredProcedures
import os
from .logging_config import security_logger as logger

# to get a string like this run:
# openssl rand -hex 32
SECRET_KEY = "09d25e094faa6ca2556c818166b7a9563b93f7099f6f0f4caa6cf63b88e8d3e7"
ALGORITHM = "HS256"
ACCESS_TOKEN_EXPIRE_MINUTES = 30
BYPASS_DB_SESSION = os.getenv("BYPASS_DB_SESSION", "false").lower() in ("1", "true", "yes")

pwd_context = CryptContext(
    schemes=["pbkdf2_sha256"],
    default="pbkdf2_sha256",
    pbkdf2_sha256__default_rounds=29000
)

def verify_password(plain_password: str, hashed_password: str) -> bool:
    return pwd_context.verify(plain_password, hashed_password)

def get_password_hash(password: str) -> str:
    return pwd_context.hash(password)

def create_access_token(data: dict, expires_delta: Optional[timedelta] = None):
    to_encode = data.copy()
    if expires_delta:
        expire = datetime.utcnow() + expires_delta
    else:
        expire = datetime.utcnow() + timedelta(minutes=15)
    to_encode.update({"exp": expire})
    encoded_jwt = jwt.encode(to_encode, SECRET_KEY, algorithm=ALGORITHM)
    return encoded_jwt

class SessionManager:
    """In-memory session manager for dev. Consider DB persistence for production."""
    active_sessions = set()
    revoked_sessions = set()

    @classmethod
    def start_session(cls) -> str:
        sid = uuid.uuid4().hex
        cls.active_sessions.add(sid)
        return sid

    @classmethod
    def revoke_session(cls, sid: str):
        if sid:
            cls.revoked_sessions.add(sid)
            if sid in cls.active_sessions:
                cls.active_sessions.remove(sid)

    @classmethod
    def is_active(cls, sid: Optional[str]) -> bool:
        return bool(sid) and (sid in cls.active_sessions) and (sid not in cls.revoked_sessions)


def _db_session_is_active(sid: Optional[str]) -> bool:
    if not sid:
        return False
    last_err = None
    for server in StoredProcedures._candidate_servers():
        try:
            conn_str = StoredProcedures._build_conn_str(server)
            conn = pyodbc.connect(conn_str)
            cur = conn.cursor()
            cur.execute("SELECT revoked_at, expires_at FROM sessions WHERE session_id = ?", (sid,))
            row = cur.fetchone()
            try:
                cur.close()
                conn.close()
            except Exception:
                pass
            if row is None:
                return False
            revoked_at, expires_at = row[0], row[1]
            if revoked_at is not None:
                return False
            # Expiry check
            try:
                # If expired, deny
                if expires_at is not None and expires_at < datetime.utcnow():
                    return False
            except Exception:
                pass
            # Touch session asynchronously (best-effort)
            try:
                from ..database import StoredProcedures as _SP
                _SP.touch_session(sid)
            except Exception:
                pass
            return True
        except Exception as e:
            last_err = e
            continue
    # If we couldn't reach DB, deny by default for safety
    logger.warning(f"Session DB check failed: {last_err}")
    return False


def verify_token(token: str):
    try:
        logger.info(f"Verifying token: {token}")
        decoded = jwt.decode(token, SECRET_KEY, algorithms=[ALGORITHM])
        logger.info(f"Token decoded successfully: {decoded}")
        # Session check (sid claim) against DB with optional bypass and in-memory fallback
        sid = decoded.get('sid')
        if BYPASS_DB_SESSION:
            logger.warning("BYPASS_DB_SESSION enabled: skipping DB session check")
            return decoded
        db_active = _db_session_is_active(sid)
        if not db_active:
            # Fallback to in-memory session for dev resiliency
            if not SessionManager.is_active(sid):
                logger.warning("Session is not active (DB) and not active in memory")
                raise HTTPException(status_code=401, detail="Session expired or logged out", headers={"X-Error-Code": "SESSION_EXPIRED"})
        return decoded
    except jwt.ExpiredSignatureError:
        logger.error("Token has expired")
        raise HTTPException(status_code=401, detail="Token has expired", headers={"X-Error-Code": "TOKEN_EXPIRED"})
    except jwt.JWTError as e:
        logger.error(f"Invalid token: {e}")
        raise HTTPException(status_code=401, detail="Invalid token", headers={"X-Error-Code": "INVALID_TOKEN"})
