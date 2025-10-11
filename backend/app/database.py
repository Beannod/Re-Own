import os
import pyodbc
from sqlalchemy import create_engine
from sqlalchemy.ext.declarative import declarative_base
from sqlalchemy.orm import sessionmaker
from .core.logging_config import db_logger as logger
from .ai_error_tracker import track_error
from datetime import datetime
from pathlib import Path
import json
import traceback

# SQL Server connection parameters (configurable via environment variables)
SERVER = os.getenv("DB_SERVER", ".\\\\SQLEXPRESS")
DATABASE = os.getenv("DB_NAME", "property_manager_db")
DRIVER = os.getenv("DB_DRIVER", "ODBC Driver 17 for SQL Server")
PORT = os.getenv("DB_PORT")

# Track which server was used effectively (for diagnostics)
LAST_USED_SERVER = None
USERNAME = os.getenv("DB_USERNAME")
PASSWORD = os.getenv("DB_PASSWORD")
TRUSTED = os.getenv("DB_TRUSTED", "true").lower() in ("1", "true", "yes")

# SQLAlchemy engine (used for ORM related tasks if needed)
server_for_url = f"{SERVER}{',' + PORT if PORT else ''}"
if TRUSTED:
    SQLSERVER_URL = f"mssql+pyodbc://{server_for_url}/{DATABASE}?driver={DRIVER.replace(' ', '+')}&trusted_connection=yes"
else:
    # SQL auth requires username and password
    SQLSERVER_URL = f"mssql+pyodbc://{USERNAME}:{PASSWORD}@{server_for_url}/{DATABASE}?driver={DRIVER.replace(' ', '+')}"
engine = create_engine(SQLSERVER_URL)

# ODBC connection string for direct stored procedure execution
server_for_odbc = f"{SERVER}{',' + PORT if PORT else ''}"
driver_seg = f"DRIVER={{{DRIVER}}};"
if TRUSTED:
    ODBC_CONN_STR = (
        driver_seg +
        f"SERVER={server_for_odbc};" +
        f"DATABASE={DATABASE};" +
        "Trusted_Connection=yes;"
    )
else:
    ODBC_CONN_STR = (
        driver_seg +
        f"SERVER={server_for_odbc};" +
        f"DATABASE={DATABASE};" +
        f"UID={USERNAME};PWD={PASSWORD};"
    )

SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)
Base = declarative_base()

def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()


class StoredProcedures:
    @staticmethod
    def _build_conn_str(server: str) -> str:
        base = driver_seg + f"SERVER={server};" + f"DATABASE={DATABASE};"
        if TRUSTED:
            return base + "Trusted_Connection=yes;"
        else:
            return base + f"UID={USERNAME};PWD={PASSWORD};"

    @staticmethod
    def _candidate_servers() -> list:
        candidates = []
        # Primary configured server
        primary = server_for_odbc

        # If running on Windows against a local SQLEXPRESS instance, prefer Named Pipes first
        prefer_np = False
        try:
            if os.name == 'nt':
                sqlexpress_aliases = {
                    r".\\SQLEXPRESS",
                    r"(local)\\SQLEXPRESS",
                    r"localhost\\SQLEXPRESS",
                    r"127.0.0.1\\SQLEXPRESS",
                }
                # If the configured server looks like a local SQLEXPRESS alias and no explicit TCP port is used, prefer NP
                prefer_np = (primary in sqlexpress_aliases) or ("SQLEXPRESS" in str(primary))
        except Exception:
            prefer_np = False

        named_pipe = r"np:\\.\pipe\MSSQL$SQLEXPRESS\sql\query"
        if prefer_np:
            candidates.append(named_pipe)
            candidates.append(primary)
        else:
            candidates.append(primary)
            # Fallbacks for local SQLEXPRESS on Windows
            try:
                if os.name == 'nt':
                    # Named Pipes default for SQLEXPRESS
                    candidates.append(named_pipe)
            except Exception:
                pass
        # Deduplicate while preserving order
        seen = set()
        uniq = []
        for s in candidates:
            if s not in seen and s:
                seen.add(s)
                uniq.append(s)
        return uniq
    @staticmethod
    def execute_sp(sp_name, params=None):
        """
        Execute a stored procedure and return the first result set as a list of dicts.
        """
        conn = None
        cursor = None
        try:
            # Try primary and fallback servers
            last_error = None
            for server in StoredProcedures._candidate_servers():
                try:
                    conn_str = StoredProcedures._build_conn_str(server)
                    logger.debug(f"Connecting to SQL Server using: {server}")
                    conn = pyodbc.connect(conn_str)
                    cursor = conn.cursor()
                    global LAST_USED_SERVER
                    LAST_USED_SERVER = server
                    break
                except Exception as ce:
                    last_error = ce
                    # Reduce noise: these failures are expected while trying fallbacks
                    logger.info(f"Connection attempt failed for server '{server}'; trying next. Details: {ce}")
                    continue
            if cursor is None:
                raise last_error or Exception("Database connection failed")

            # Trace SP execution details
            logger.debug(f"Executing SP {sp_name} with params: {params}")
            logger.debug(f"Parameter count: {len(params) if params else 0}")
            if params:
                # Use proper parameterized queries instead of string concatenation
                placeholders = ', '.join(['?'] * len(params))
                sql = f"EXEC {sp_name} {placeholders}"
                cursor.execute(sql, params)
            else:
                cursor.execute(f"EXEC {sp_name}")

            # If there is a result set, fetch and map to dicts BEFORE any commit
            results = None
            if cursor.description:
                columns = [col[0] for col in cursor.description]
                rows = cursor.fetchall()
                results = [dict(zip(columns, row)) for row in rows]

            # consume any remaining result sets (ignore errors if none)
            try:
                while cursor.nextset():
                    # Intentionally not touching results further
                    pass
            except Exception:
                pass

            # Commit after consuming result sets
            conn.commit()
            logger.debug(f"SP {sp_name} executed successfully; results: {results}")
            return results

        except Exception as e:
            # Track and log DB execution errors
            logger.error(f"Stored procedure '{sp_name}' failed: {e}")
            # Try smart fallbacks for known SPs if they are missing
            try:
                msg = str(e).lower()
                if ("could not find stored procedure" in msg or "does not exist" in msg):
                    if sp_name.lower() == 'sp_getactiveleasebyproperty' and params and len(params) == 1:
                        # Fallback to direct query
                        q = (
                            "SELECT TOP 1 * FROM leases WHERE unit_id = ? AND status = 'active' "
                            "AND (end_date IS NULL OR end_date > GETDATE()) ORDER BY start_date DESC"
                        )
                        return StoredProcedures.execute_query(q, params)
            except Exception:
                pass
            try:
                StoredProcedures._log_sql_error(e, sp_name, params)
            except Exception as le:
                logger.error(f"Failed to log SQL error: {le}")
            try:
                track_error(
                    error=e,
                    context="Stored procedure execution",
                    user_action=f"EXEC {sp_name}",
                    endpoint=f"db:{sp_name}",
                    request_data={"sp_name": sp_name, "params": params},
                    severity="CRITICAL"
                )
            except Exception:
                pass
            raise
        finally:
            try:
                if cursor is not None:
                    cursor.close()
            except Exception:
                pass
            try:
                if conn is not None:
                    conn.close()
            except Exception:
                pass

    @staticmethod
    def _log_sql_error(error: Exception, sp_name: str, params):
        """Write SQL errors to a dedicated JSONL-like log file for quick triage."""
        try:
            log_path = Path(os.getcwd()) / "sql_error_log.json"
            entry = {
                "timestamp": datetime.utcnow().isoformat() + "Z",
                "stored_procedure": sp_name,
                "params": params,
                "error_type": type(error).__name__,
                "error_message": str(error),
                "error_args": getattr(error, 'args', None),
                "server": LAST_USED_SERVER,
                "traceback": traceback.format_exc(),
            }

            # Read-existing or init
            if log_path.exists():
                try:
                    with open(log_path, 'r', encoding='utf-8') as f:
                        data = json.load(f)
                except Exception:
                    data = {"errors": []}
            else:
                data = {"errors": []}

            data.setdefault("errors", []).append(entry)
            # Keep last 200 entries
            if len(data["errors"]) > 200:
                data["errors"] = data["errors"][-200:]

            with open(log_path, 'w', encoding='utf-8') as f:
                json.dump(data, f, indent=2)
        except Exception as e:
                logger.error(f"_log_sql_error failed: {e}")

    @staticmethod
    def test_connection():
        """Attempt to connect and return basic server info for diagnostics."""
        info = {
            "server": SERVER,
            "database": DATABASE,
            "driver": DRIVER,
            "trusted_connection": TRUSTED,
        }
        try:
            last_error = None
            used = None
            for server in StoredProcedures._candidate_servers():
                try:
                    conn_str = StoredProcedures._build_conn_str(server)
                    conn = pyodbc.connect(conn_str, timeout=5)
                    cursor = conn.cursor()
                    cursor.execute("SELECT @@VERSION as version")
                    row = cursor.fetchone()
                    info["status"] = "ok"
                    info["version"] = row.version if row else "unknown"
                    used = server
                    break
                except Exception as ce:
                    last_error = ce
                    continue
            if used:
                info["effective_server"] = used
            else:
                raise last_error or Exception("Database connection failed")
        except Exception as e:
            info["status"] = "error"
            info["error"] = str(e)
            try:
                track_error(
                    error=e,
                    context="Database connection test",
                    user_action="Connecting via pyodbc",
                    endpoint="db:test_connection",
                    request_data={
                        "server": SERVER,
                        "database": DATABASE,
                        "driver": DRIVER,
                        "trusted": TRUSTED,
                    },
                    severity="CRITICAL"
                )
            except Exception:
                pass
        finally:
            try:
                cursor.close()
                conn.close()
            except Exception:
                pass
        return info

    # User Management
    @staticmethod
    def create_user(email, username, hashed_password, full_name, role):
        try:
            logger.info(f"Executing sp_CreateUser with params: email={email}, username={username}, role={role}")
            result = StoredProcedures.execute_sp(
                "sp_CreateUser",
                [email, username, hashed_password, full_name, role]
            )
            logger.info(f"sp_CreateUser result: {result}")
            return result
        except Exception as e:
            logger.error(f"Error creating user: {e}")
            raise

    # Session Management (direct SQL for simplicity)
    @staticmethod
    def create_session(session_id: str, user_id: int):
        conn = None
        try:
            # Use the same connection routine
            for server in StoredProcedures._candidate_servers():
                try:
                    conn_str = StoredProcedures._build_conn_str(server)
                    conn = pyodbc.connect(conn_str)
                    cursor = conn.cursor()
                    cursor.execute(
                        "INSERT INTO sessions (session_id, user_id, created_at, expires_at, last_seen) VALUES (?, ?, GETDATE(), DATEADD(MINUTE, 30, GETDATE()), GETDATE())",
                        (session_id, user_id)
                    )
                    conn.commit()
                    return True
                except Exception:
                    continue
            raise Exception("Failed to create session")
        finally:
            try:
                if conn:
                    conn.close()
            except Exception:
                pass

    @staticmethod
    def revoke_session(session_id: str):
        conn = None
        try:
            for server in StoredProcedures._candidate_servers():
                try:
                    conn_str = StoredProcedures._build_conn_str(server)
                    conn = pyodbc.connect(conn_str)
                    cursor = conn.cursor()
                    cursor.execute(
                        "UPDATE sessions SET revoked_at = GETDATE(), last_seen = GETDATE() WHERE session_id = ?",
                        (session_id,)
                    )
                    conn.commit()
                    return True
                except Exception:
                    continue
            raise Exception("Failed to revoke session")
        finally:
            try:
                if conn:
                    conn.close()
            except Exception:
                pass

    @staticmethod
    def touch_session(session_id: str):
        """Update last_seen and extend expiry on activity (sliding window)."""
        conn = None
        try:
            for server in StoredProcedures._candidate_servers():
                try:
                    conn_str = StoredProcedures._build_conn_str(server)
                    conn = pyodbc.connect(conn_str)
                    cursor = conn.cursor()
                    cursor.execute(
                        "UPDATE sessions SET last_seen = GETDATE(), expires_at = DATEADD(MINUTE, 30, GETDATE()) WHERE session_id = ? AND revoked_at IS NULL",
                        (session_id,)
                    )
                    conn.commit()
                    return True
                except Exception:
                    continue
            return False
        finally:
            try:
                if conn:
                    conn.close()
            except Exception:
                pass

    @staticmethod
    def update_user(user_id, email, username, full_name, role):
        return StoredProcedures.execute_sp(
            "sp_UpdateUser",
            [user_id, email, username, full_name, role]
        )

    @staticmethod
    def delete_user(user_id):
        return StoredProcedures.execute_sp("sp_DeleteUser", [user_id])

    @staticmethod
    def set_user_password_hashed(user_id, hashed_password):
        """Update user's hashed password (used for secure migration)."""
        return StoredProcedures.execute_sp(
            "sp_SetUserPasswordHashed",
            [user_id, hashed_password]
        )

    # Property Management
    @staticmethod
    def create_property(owner_id, title, address, property_type, bedrooms,
                       bathrooms, area, rent_amount, deposit_amount, description, status):
        try:
            return StoredProcedures.execute_sp(
                "sp_CreateProperty",
                [owner_id, title, address, property_type, bedrooms,
                 bathrooms, area, rent_amount, deposit_amount, description, status]
            )
        except Exception as e:
            msg = str(e).lower()
            if ("could not find stored procedure" in msg or 
                "invalid object name 'sp_createproperty'" in msg or 
                "does not exist" in msg or 
                "too many arguments specified" in msg):
                # Fallback to direct insert
                return StoredProcedures._direct_insert_property(owner_id, title, address, property_type, bedrooms,
                                                                bathrooms, area, rent_amount, deposit_amount, description, status)
            raise

    @staticmethod
    def update_property(property_id, title, address, property_type, bedrooms,
                       bathrooms, area, rent_amount, deposit_amount, description, status):
        try:
            return StoredProcedures.execute_sp(
                "sp_UpdateProperty",
                [property_id, title, address, property_type, bedrooms,
                 bathrooms, area, rent_amount, deposit_amount, description, status]
            )
        except Exception as e:
            msg = str(e).lower()
            if ("could not find stored procedure" in msg or 
                "does not exist" in msg or 
                "too many arguments specified" in msg):
                return StoredProcedures._direct_update_property(property_id, title, address, property_type, bedrooms,
                                                                bathrooms, area, rent_amount, deposit_amount, description, status)
            raise

    @staticmethod
    def delete_property(property_id):
        try:
            return StoredProcedures.execute_sp("sp_DeleteProperty", [property_id])
        except Exception as e:
            msg = str(e).lower()
            if "could not find stored procedure" in msg or "does not exist" in msg:
                return StoredProcedures._direct_delete_property(property_id)
            raise

    @staticmethod
    def _direct_insert_property(owner_id, title, address, property_type, bedrooms,
                                bathrooms, area, rent_amount, deposit_amount, description, status):
        """Fallback insert into properties when SP is missing."""
        conn = None
        try:
            # Connect using same candidate servers
            last_error = None
            for server in StoredProcedures._candidate_servers():
                try:
                    conn_str = StoredProcedures._build_conn_str(server)
                    conn = pyodbc.connect(conn_str)
                    cursor = conn.cursor()
                    break
                except Exception as ce:
                    last_error = ce
                    continue
            if conn is None:
                raise last_error or Exception("Database connection failed")

            # First check if deposit_amount column exists
            try:
                cursor.execute("SELECT COL_LENGTH('properties', 'deposit_amount')")
                has_deposit_col = cursor.fetchone()[0] is not None
            except Exception:
                has_deposit_col = False

            if has_deposit_col:
                sql = (
                    "INSERT INTO properties (owner_id, title, address, property_type, bedrooms, bathrooms, area, rent_amount, deposit_amount, description, status, created_at) "
                    "OUTPUT Inserted.id as PropertyId "
                    "VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, GETDATE())"
                )
                cursor.execute(sql, (owner_id, title, address, property_type, bedrooms, bathrooms, area, rent_amount, deposit_amount, description, status))
            else:
                # Fallback without deposit_amount column
                sql = (
                    "INSERT INTO properties (owner_id, title, address, property_type, bedrooms, bathrooms, area, rent_amount, description, status, created_at) "
                    "OUTPUT Inserted.id as PropertyId "
                    "VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, GETDATE())"
                )
                cursor.execute(sql, (owner_id, title, address, property_type, bedrooms, bathrooms, area, rent_amount, description, status))
            
            row = cursor.fetchone()
            conn.commit()
            return [{"PropertyId": row.PropertyId if row else None}]
        finally:
            try:
                cursor.close()
            except Exception:
                pass
            try:
                if conn:
                    conn.close()
            except Exception:
                pass

    @staticmethod
    def _direct_update_property(property_id, title, address, property_type, bedrooms,
                                bathrooms, area, rent_amount, deposit_amount, description, status):
        conn = None
        try:
            for server in StoredProcedures._candidate_servers():
                try:
                    conn_str = StoredProcedures._build_conn_str(server)
                    conn = pyodbc.connect(conn_str)
                    cursor = conn.cursor()
                    break
                except Exception:
                    continue
            if conn is None:
                raise Exception("Database connection failed")
            
            # Check if deposit_amount column exists
            try:
                cursor.execute("SELECT COL_LENGTH('properties', 'deposit_amount')")
                has_deposit_col = cursor.fetchone()[0] is not None
            except Exception:
                has_deposit_col = False

            if has_deposit_col:
                sql = (
                    "UPDATE properties SET title=?, address=?, property_type=?, bedrooms=?, bathrooms=?, area=?, rent_amount=?, deposit_amount=?, description=?, status=?, updated_at=GETDATE() WHERE id=?"
                )
                cursor.execute(sql, (title, address, property_type, bedrooms, bathrooms, area, rent_amount, deposit_amount, description, status, property_id))
            else:
                # Fallback without deposit_amount column
                sql = (
                    "UPDATE properties SET title=?, address=?, property_type=?, bedrooms=?, bathrooms=?, area=?, rent_amount=?, description=?, status=?, updated_at=GETDATE() WHERE id=?"
                )
                cursor.execute(sql, (title, address, property_type, bedrooms, bathrooms, area, rent_amount, description, status, property_id))
            
            affected = cursor.rowcount
            conn.commit()
            return [{"AffectedRows": affected}]
        finally:
            try:
                cursor.close()
            except Exception:
                pass
            try:
                if conn:
                    conn.close()
            except Exception:
                pass

    @staticmethod
    def _direct_delete_property(property_id):
        conn = None
        try:
            for server in StoredProcedures._candidate_servers():
                try:
                    conn_str = StoredProcedures._build_conn_str(server)
                    conn = pyodbc.connect(conn_str)
                    cursor = conn.cursor()
                    break
                except Exception:
                    continue
            if conn is None:
                raise Exception("Database connection failed")
            cursor.execute("UPDATE properties SET status='deleted', updated_at=GETDATE() WHERE id=?", (property_id,))
            affected = cursor.rowcount
            conn.commit()
            return [{"AffectedRows": affected}]
        finally:
            try:
                cursor.close()
            except Exception:
                pass
            try:
                if conn:
                    conn.close()
            except Exception:
                pass

    # Payment Management
    @staticmethod
    def create_payment(property_id, tenant_id, amount, payment_type,
                      payment_method, payment_status, payment_date):
        return StoredProcedures.execute_sp(
            "sp_CreatePayment",
            [property_id, tenant_id, amount, payment_type,
             payment_method, payment_status, payment_date]
        )

    @staticmethod
    def update_payment_status(payment_id, payment_status):
        return StoredProcedures.execute_sp(
            "sp_UpdatePaymentStatus",
            [payment_id, payment_status]
        )

    # Utility Management
    @staticmethod
    def create_utility_reading(property_id, utility_type, reading_date,
                             reading_value, amount, status):
        return StoredProcedures.execute_sp(
            "sp_CreateUtilityReading",
            [property_id, utility_type, reading_date,
             reading_value, amount, status]
        )

    @staticmethod
    def update_utility_reading(utility_id, reading_value, amount, status):
        return StoredProcedures.execute_sp(
            "sp_UpdateUtilityReading",
            [utility_id, reading_value, amount, status]
        )

    # Reports
    @staticmethod
    def get_property_occupancy_report(owner_id=None, start_date=None, end_date=None):
        return StoredProcedures.execute_sp(
            "sp_GetPropertyOccupancyReport",
            [owner_id, start_date, end_date]
        )

    @staticmethod
    def get_payment_collection_report(owner_id=None, start_date=None, end_date=None):
        return StoredProcedures.execute_sp(
            "sp_GetPaymentCollectionReport",
            [owner_id, start_date, end_date]
        )

    @staticmethod
    def get_utility_consumption_report(property_id=None, utility_type=None,
                                     start_date=None, end_date=None):
        return StoredProcedures.execute_sp(
            "sp_GetUtilityConsumptionReport",
            [property_id, utility_type, start_date, end_date]
        )

    # Owner/Renter Profiles
    @staticmethod
    def create_owner_profile(user_id, phone=None, address=None, company=None):
        return StoredProcedures.execute_sp(
            "sp_CreateOwnerProfile",
            [user_id, phone, address, company]
        )

    @staticmethod
    def update_owner_profile(user_id, phone=None, address=None, company=None):
        return StoredProcedures.execute_sp(
            "sp_UpdateOwnerProfile",
            [user_id, phone, address, company]
        )

    @staticmethod
    def get_owner_profile(user_id):
        return StoredProcedures.execute_sp(
            "sp_GetOwnerProfile",
            [user_id]
        )

    @staticmethod
    def create_renter_profile(user_id, phone=None, address=None, lease_start=None, lease_end=None):
        return StoredProcedures.execute_sp(
            "sp_CreateRenterProfile",
            [user_id, phone, address, lease_start, lease_end]
        )

    @staticmethod
    def update_renter_profile(user_id, phone=None, address=None, lease_start=None, lease_end=None):
        return StoredProcedures.execute_sp(
            "sp_UpdateRenterProfile",
            [user_id, phone, address, lease_start, lease_end]
        )

    @staticmethod
    def get_renter_profile(user_id):
        return StoredProcedures.execute_sp(
            "sp_GetRenterProfile",
            [user_id]
        )

    # Property documents
    @staticmethod
    def add_property_document(property_id, file_name, file_path, content_type=None):
        return StoredProcedures.execute_sp(
            "sp_AddPropertyDocument",
            [property_id, file_name, file_path, content_type]
        )

    @staticmethod
    def list_property_documents(property_id):
        return StoredProcedures.execute_sp(
            "sp_ListPropertyDocuments",
            [property_id]
        )

    @staticmethod
    def delete_property_document(document_id):
        return StoredProcedures.execute_sp(
            "sp_DeletePropertyDocument",
            [document_id]
        )

    # Leases
    @staticmethod
    def create_lease(tenant_id, unit_id, start_date, end_date, rent_amount, deposit_amount, status="active"):
        try:
            return StoredProcedures.execute_sp(
                "sp_CreateLease",
                [tenant_id, unit_id, start_date, end_date, rent_amount, deposit_amount, status]
            )
        except Exception as e:
            msg = str(e).lower()
            if ("could not find stored procedure" in msg or "does not exist" in msg):
                # Direct insert fallback if SP missing
                query = (
                    "INSERT INTO leases (tenant_id, unit_id, start_date, end_date, rent_amount, deposit_amount, status, created_at) "
                    "OUTPUT Inserted.id as LeaseId "
                    "VALUES (?, ?, ?, ?, ?, ?, ?, GETDATE())"
                )
                result = StoredProcedures.execute_query(query, [tenant_id, unit_id, start_date, end_date, rent_amount, deposit_amount, status])
                return [{"LeaseId": result[0]["LeaseId"]}] if result else None
            raise

    @staticmethod
    def get_lease(lease_id):
        return StoredProcedures.execute_sp("sp_GetLease", [lease_id])

    @staticmethod
    def update_lease(lease_id, start_date=None, end_date=None, rent_amount=None, deposit_amount=None, status=None):
        return StoredProcedures.execute_sp(
            "sp_UpdateLease",
            [lease_id, start_date, end_date, rent_amount, deposit_amount, status]
        )

    @staticmethod
    def list_leases(tenant_id=None, unit_id=None):
        return StoredProcedures.execute_sp(
            "sp_ListLeases",
            [tenant_id, unit_id]
        )

    @staticmethod
    def get_active_lease_by_property(property_id: int):
        """Return active lease rows for a property. Falls back to direct SQL if SP is missing."""
        try:
            return StoredProcedures.execute_sp("sp_GetActiveLeaseByProperty", [property_id])
        except Exception as e:
            # Fallback if stored procedure doesn't exist in target DB
            msg = str(e).lower()
            if ("could not find stored procedure" in msg) or ("does not exist" in msg):
                query = (
                    "SELECT TOP 1 * FROM leases "
                    "WHERE unit_id = ? AND status = 'active' "
                    "AND (end_date IS NULL OR end_date > GETDATE()) "
                    "ORDER BY start_date DESC"
                )
                rows = StoredProcedures.execute_query(query, [property_id])
                return rows
            # Otherwise bubble up
            raise

    # Lease Invitations helpers
    @staticmethod
    def create_lease_invitation(owner_id, renter_id, property_id, start_date, rent_amount, deposit_amount=None):
        return StoredProcedures.execute_sp(
            "sp_CreateLeaseInvitation",
            [owner_id, renter_id, property_id, start_date, rent_amount, deposit_amount]
        )

    @staticmethod
    def list_lease_invitations_for_renter(renter_id):
        return StoredProcedures.execute_sp(
            "sp_ListLeaseInvitationsForRenter",
            [renter_id]
        )

    @staticmethod
    def approve_lease_invitation(invitation_id):
        return StoredProcedures.execute_sp(
            "sp_ApproveLeaseInvitation",
            [invitation_id]
        )

    @staticmethod
    def reject_lease_invitation(invitation_id):
        return StoredProcedures.execute_sp(
            "sp_RejectLeaseInvitation",
            [invitation_id]
        )

    @staticmethod
    def execute_query(query, params=None):
        """
        Execute a raw SQL query and return the result.
        """
        conn = None
        cursor = None
        try:
            # Try primary and fallback servers
            last_error = None
            for server in StoredProcedures._candidate_servers():
                try:
                    conn_str = StoredProcedures._build_conn_str(server)
                    logger.debug(f"Connecting to SQL Server using: {server}")
                    conn = pyodbc.connect(conn_str)
                    cursor = conn.cursor()
                    global LAST_USED_SERVER
                    LAST_USED_SERVER = server
                    break
                except Exception as ce:
                    last_error = ce
                    logger.warning(f"Connection attempt failed for server '{server}': {ce}")
                    continue
            if cursor is None:
                raise last_error or Exception("Database connection failed")

            # Execute the query
            if params:
                cursor.execute(query, params)
            else:
                cursor.execute(query)
            
            upper = query.strip().upper()
            # For SELECT queries, fetch results BEFORE any commit to avoid invalidating cursor
            if upper.startswith('SELECT'):
                columns = [column[0] for column in cursor.description]
                rows = cursor.fetchall()
                # No commit needed for pure SELECT; return rows as list of dicts
                return [dict(zip(columns, row)) for row in rows]
            else:
                # Commit the transaction for UPDATE/INSERT/DDL queries and return affected rows
                conn.commit()
                return cursor.rowcount
                
        except Exception as e:
            logger.error(f"Error executing query '{query}' with params {params}: {str(e)}")
            try:
                StoredProcedures._log_sql_error(e, f"RAW_QUERY: {query}", params)
            except Exception:
                pass
            try:
                track_error(
                    error=e,
                    context="Raw query execution",
                    user_action=f"QUERY: {query}",
                    endpoint="db:raw_query",
                    request_data={"query": query, "params": params},
                    severity="CRITICAL"
                )
            except Exception:
                pass
            raise
        finally:
            try:
                if cursor is not None:
                    cursor.close()
            except Exception:
                pass
            try:
                if conn is not None:
                    conn.close()
            except Exception:
                pass
