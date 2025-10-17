from backend.app.core.logging_config import get_logger, log_exception

app_logger = get_logger('app')

def log_dependency_event(msg):
    app_logger.info(msg)

def log_dependency_error(msg, exc=None):
    if exc:
        log_exception(app_logger, msg, exc)
    else:
        app_logger.error(msg)
from fastapi import Request, HTTPException, status, Depends
from ..core import security
import logging

def get_current_user(request: Request):
    """
    Authentication dependency that verifies JWT token and returns user info.
    Use this as a dependency in all protected endpoints.
    """
    auth = request.headers.get('Authorization')
    if not auth:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Not authenticated",
            headers={"X-Error-Code": "NOT_AUTHENTICATED"}
        )
    
    try:
        scheme, token = auth.split(' ', 1)
        if scheme.lower() != 'bearer':
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="Invalid authentication scheme",
                headers={"X-Error-Code": "INVALID_AUTH_SCHEME"}
            )
        
        # Verify token and get user info
        decoded = security.verify_token(token)
        
        return {
            'user_id': int(decoded.get('user_id')),
            'email': decoded.get('sub'),
            'role': decoded.get('role'),
            'session_id': decoded.get('sid')
        }
        
    except HTTPException:
        raise
    except ValueError:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid authorization header format",
            headers={"X-Error-Code": "INVALID_AUTH_FORMAT"}
        )
    except Exception as e:
        logging.error(f"Authentication error: {e}")
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Authentication failed",
            headers={"X-Error-Code": "AUTH_FAILED"}
        )

def require_role(required_role: str):
    """
    Role-based authorization dependency factory.
    Usage: Depends(require_role("owner"))
    """
    def role_checker(current_user: dict = Depends(get_current_user)):
        if current_user['role'] != required_role:
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail=f"Access denied. Required role: {required_role}",
                headers={"X-Error-Code": "INSUFFICIENT_PERMISSIONS"}
            )
        return current_user
    return role_checker

def require_owner_access(current_user: dict = Depends(get_current_user)):
    """Dependency for owner-only endpoints"""
    if current_user['role'] != 'owner':
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Access denied. Owner role required.",
            headers={"X-Error-Code": "OWNER_ACCESS_REQUIRED"}
        )
    return current_user

def require_renter_access(current_user: dict = Depends(get_current_user)):
    """Dependency for renter-only endpoints"""
    if current_user['role'] != 'renter':
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Access denied. Renter role required.",
            headers={"X-Error-Code": "RENTER_ACCESS_REQUIRED"}
        )
    return current_user

def require_any_authenticated(current_user: dict = Depends(get_current_user)):
    """Dependency for endpoints that require any authenticated user"""
    return current_user