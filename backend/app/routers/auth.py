from fastapi import APIRouter, HTTPException, status, Depends
from typing import List
from ..database import StoredProcedures
from ..schemas import user as user_schema
from ..core import security
from ..core.dependencies import require_owner_access
from backend.app.core.logging_config import get_logger, log_exception
import logging
import pyodbc
from datetime import timedelta

auth_logger = get_logger('auth')
security_logger = get_logger('security')

def log_auth_event(msg):
    auth_logger.info(msg)

def log_auth_error(msg, exc=None):
    if exc:
        log_exception(auth_logger, msg, exc)
    else:
        auth_logger.error(msg)

router = APIRouter(
    prefix="/auth",
    tags=["Authentication"]
)

@router.post("/register")
def register(user_data: user_schema.UserCreate):
    try:
        # Check if email already exists
        try:
            existing = StoredProcedures.execute_sp("sp_GetUserByEmail", [user_data.email])
            if existing:
                raise HTTPException(
                    status_code=status.HTTP_409_CONFLICT,
                    detail="Email already registered",
                    headers={"X-Error-Code": "EMAIL_EXISTS"}
                )
        except HTTPException:
            raise
        except Exception:
            # Non-fatal: if lookup fails, proceed and rely on unique constraint handling
            logging.warning("sp_GetUserByEmail check failed during registration; continuing to create user")

        # Hash the password
        hashed_password = security.get_password_hash(user_data.password)

        # Create new user using stored procedure
        result = StoredProcedures.create_user(
            email=user_data.email,
            username=user_data.username,
            hashed_password=hashed_password,
            full_name=user_data.full_name,
            role=user_data.role
        )

        if not result:
            raise HTTPException(status_code=400, detail="Failed to create user", headers={"X-Error-Code": "CREATE_USER_FAILED"})

        user_id = result[0]['UserId']

        # Create role-specific profile shell
        if user_data.role == 'owner':
            StoredProcedures.create_owner_profile(user_id)
        elif user_data.role == 'renter':
            StoredProcedures.create_renter_profile(user_id)
        return {
            "id": user_id,
            "email": user_data.email,
            "username": user_data.username,
            "full_name": user_data.full_name,
            "role": user_data.role,
            "is_active": True
        }
    except HTTPException as he:
        # pass through
        raise he
    except pyodbc.IntegrityError as ie:
        # Likely unique constraint violation on email or username
        msg = str(ie)
        logging.error(f"Integrity error on register: {msg}")
        # Try to infer which field
        code = "DUPLICATE"
        detail = "Duplicate value"
        lower = msg.lower()
        if "email" in lower:
            code = "EMAIL_EXISTS"
            detail = "Email already registered"
        elif "username" in lower:
            code = "USERNAME_EXISTS"
            detail = "Username already taken"
        raise HTTPException(status_code=status.HTTP_409_CONFLICT, detail=detail, headers={"X-Error-Code": code})
    except Exception as e:
        # log minimal server-side error and return 400
        import traceback
        traceback.print_exc()
        raise HTTPException(status_code=400, detail=str(e), headers={"X-Error-Code": "UNKNOWN_REGISTER_ERROR"})

@router.post("/login")
def login(user_data: user_schema.UserLogin):
    # Get user by email using stored procedure
    result = StoredProcedures.execute_sp("sp_GetUserByEmail", [user_data.email])
    
    if not result:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Email address not found",
            headers={"X-Error-Code": "EMAIL_NOT_FOUND"}
        )
    
    user = result[0]
    # Always verify securely against hashed password; plaintext storage is not supported.
    if not security.verify_password(user_data.password, user['hashed_password']):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid password",
            headers={"X-Error-Code": "INVALID_PASSWORD"}
        )
    
    # Start a session and create access token including user id, role, and session id (sid)
    sid = security.SessionManager.start_session()
    # Persist session in DB (best-effort)
    try:
        StoredProcedures.create_session(sid, int(user['id']))
    except Exception:
        pass
    token_data = {"sub": user['email'], "user_id": user['id'], "role": user['role'], "sid": sid}
    access_token = security.create_access_token(
        data=token_data,
        expires_delta=timedelta(minutes=security.ACCESS_TOKEN_EXPIRE_MINUTES)
    )
    return {"access_token": access_token, "token_type": "bearer", "session_id": sid}


from fastapi import Request


@router.get('/me')
def me(request: Request):
    auth = request.headers.get('Authorization')
    if not auth:
        raise HTTPException(status_code=401, detail='Not authenticated', headers={"X-Error-Code": "NOT_AUTHENTICATED"})
    try:
        scheme, token = auth.split()
        # validate token
        security.verify_token(token)
        from jose import jwt as _jwt
        decoded = _jwt.decode(token, security.SECRET_KEY, algorithms=[security.ALGORITHM])
    except Exception:
        raise HTTPException(status_code=401, detail='Invalid token', headers={"X-Error-Code": "INVALID_TOKEN"})
    return {
        'email': decoded.get('sub'),
        'user_id': decoded.get('user_id'),
        'role': decoded.get('role'),
        'session_id': decoded.get('sid')
    }

@router.get('/owner-analytics')
def get_owner_analytics(current_user: dict = Depends(require_owner_access)):
    """
    Get comprehensive analytics for the owner dashboard.
    Returns KPIs: total properties, active tenants, monthly revenue, occupancy rate, etc.
    """
    owner_id = current_user['user_id']
    
    try:
        # Get all properties for owner
        properties = StoredProcedures.execute_sp("sp_GetAllProperties", [owner_id]) or []
        total_properties = len(properties)
        
        # Count available and occupied properties
        available_properties = sum(1 for p in properties if p.get('status', '').lower() in ['available', 'vacant'])
        occupied_properties = sum(1 for p in properties if p.get('status', '').lower() in ['occupied', 'rented'])
        
        # Calculate occupancy rate
        occupancy_rate = (occupied_properties / total_properties * 100) if total_properties > 0 else 0
        
        # Get active tenants (leases)
        try:
            from ..database import get_db_connection
            conn = get_db_connection()
            cursor = conn.cursor()
            
            # Count active tenants
            cursor.execute("""
                SELECT COUNT(DISTINCT tenant_id) 
                FROM leases 
                WHERE property_id IN (
                    SELECT id FROM properties WHERE owner_id = ?
                ) AND is_active = 1
            """, (owner_id,))
            active_tenants = cursor.fetchone()[0] or 0
            
            # Calculate monthly revenue (sum of rent from active leases)
            cursor.execute("""
                SELECT COALESCE(SUM(rent_amount), 0) 
                FROM leases 
                WHERE property_id IN (
                    SELECT id FROM properties WHERE owner_id = ?
                ) AND is_active = 1
            """, (owner_id,))
            monthly_revenue = float(cursor.fetchone()[0] or 0)
            
            # Get pending payments
            cursor.execute("""
                SELECT COALESCE(SUM(amount), 0)
                FROM payments p
                JOIN leases l ON p.lease_id = l.id
                WHERE l.property_id IN (
                    SELECT id FROM properties WHERE owner_id = ?
                ) AND p.payment_status IN ('pending', 'failed')
            """, (owner_id,))
            pending_amount = float(cursor.fetchone()[0] or 0)
            
            # Calculate collection rate (completed payments / total expected)
            cursor.execute("""
                SELECT 
                    COALESCE(SUM(CASE WHEN payment_status = 'completed' THEN amount ELSE 0 END), 0) as collected,
                    COALESCE(SUM(amount), 0) as total
                FROM payments p
                JOIN leases l ON p.lease_id = l.id
                WHERE l.property_id IN (
                    SELECT id FROM properties WHERE owner_id = ?
                ) AND MONTH(p.payment_date) = MONTH(GETDATE())
                  AND YEAR(p.payment_date) = YEAR(GETDATE())
            """, (owner_id,))
            row = cursor.fetchone()
            collected = float(row[0] or 0)
            total = float(row[1] or 0)
            collection_rate = (collected / total * 100) if total > 0 else 0
            
            cursor.close()
            conn.close()
            
        except Exception as e:
            print(f"Error fetching tenant/payment stats: {e}")
            active_tenants = 0
            monthly_revenue = 0
            pending_amount = 0
            collection_rate = 0
        
        return {
            "totalProperties": total_properties,
            "availableProperties": available_properties,
            "occupiedProperties": occupied_properties,
            "occupancyRate": round(occupancy_rate, 1),
            "activeTenants": active_tenants,
            "monthlyRevenue": round(monthly_revenue, 2),
            "pendingAmount": round(pending_amount, 2),
            "collectionRate": round(collection_rate, 1)
        }
    except Exception as e:
        import traceback
        traceback.print_exc()
        raise HTTPException(
            status_code=500,
            detail=f"Failed to fetch owner analytics: {str(e)}",
            headers={"X-Error-Code": "ANALYTICS_ERROR"}
        )


@router.post('/logout')
def logout(request: Request):
    auth = request.headers.get('Authorization')
    if not auth:
        raise HTTPException(status_code=401, detail='Not authenticated', headers={"X-Error-Code": "NOT_AUTHENTICATED"})
    try:
        _, token = auth.split()
        decoded = security.verify_token(token)
        sid = decoded.get('sid')
        security.SessionManager.revoke_session(sid)
        try:
            StoredProcedures.revoke_session(sid)
        except Exception:
            pass
        return {"message": "Logged out", "session_id": sid}
    except HTTPException:
        raise
    except Exception:
        raise HTTPException(status_code=401, detail='Invalid token', headers={"X-Error-Code": "INVALID_TOKEN"})

@router.get('/user-preferences')
def get_user_preferences(request: Request):
    """Get current user's preferences including dark mode setting"""
    auth = request.headers.get('Authorization')
    if not auth:
        raise HTTPException(status_code=401, detail='Not authenticated', headers={"X-Error-Code": "NOT_AUTHENTICATED"})
    
    try:
        _, token = auth.split()
        decoded = security.verify_token(token)
        user_id = decoded.get('user_id')
        
        # Get user preferences from database
        result = StoredProcedures.execute_sp("sp_GetUserById", [user_id])
        if not result:
            raise HTTPException(status_code=404, detail='User not found')
            
        user = result[0]
        return {
            "dark_mode": user.get('dark_mode', False),
            "notification_preferences": user.get('notification_preferences')
        }
    except HTTPException:
        raise
    except Exception as e:
        logging.error(f"Error getting user preferences: {str(e)}")
        raise HTTPException(status_code=500, detail='Failed to get user preferences')

@router.put('/user-preferences')
def update_user_preferences(preferences: user_schema.UserPreferencesUpdate, request: Request):
    """Update current user's preferences including dark mode setting"""
    auth = request.headers.get('Authorization')
    if not auth:
        raise HTTPException(status_code=401, detail='Not authenticated', headers={"X-Error-Code": "NOT_AUTHENTICATED"})
    
    try:
        _, token = auth.split()
        decoded = security.verify_token(token)
        user_id = decoded.get('user_id')
        
        # Update user preferences in database
        params = [user_id]
        update_fields = []
        
        if preferences.dark_mode is not None:
            update_fields.append("dark_mode = ?")
            params.append(preferences.dark_mode)
            
        if preferences.notification_preferences is not None:
            update_fields.append("notification_preferences = ?")
            params.append(preferences.notification_preferences)
            
        if not update_fields:
            raise HTTPException(status_code=400, detail='No preferences to update')
            
        # Execute update query
        query = f"UPDATE users SET {', '.join(update_fields)} WHERE id = ?"
        StoredProcedures.execute_query(query, params)
        
        return {"message": "Preferences updated successfully"}
    except HTTPException:
        raise
    except Exception as e:
        logging.error(f"Error updating user preferences: {str(e)}")
        raise HTTPException(status_code=500, detail='Failed to update user preferences')
