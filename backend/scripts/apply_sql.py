import os
import sys
import pyodbc
from pathlib import Path

# Module-level verbose flag (can be enabled via --verbose or APPLY_SQL_VERBOSE env var)
VERBOSE = False

# Reads and executes one or more .sql files against the configured SQL Server database.
# Uses the same environment variables as the app: DB_SERVER, DB_NAME, DB_DRIVER, DB_USERNAME, DB_PASSWORD, DB_TRUSTED, DB_PORT

DRIVER = os.getenv("DB_DRIVER", "ODBC Driver 17 for SQL Server")
SERVER = os.getenv("DB_SERVER", ".\\SQLEXPRESS")
DATABASE = os.getenv("DB_NAME", "property_manager_db")
PORT = os.getenv("DB_PORT")
USERNAME = os.getenv("DB_USERNAME")
PASSWORD = os.getenv("DB_PASSWORD")
TRUSTED = os.getenv("DB_TRUSTED", "true").lower() in ("1", "true", "yes")

server = f"{SERVER}{',' + PORT if PORT else ''}"
# Don't set DATABASE in the connection string so we can run CREATE/DROP DATABASE statements
base_conn = f"DRIVER={{{DRIVER}}};SERVER={server};"
if TRUSTED:
    CONN_STR = base_conn + "Trusted_Connection=yes;"
else:
    if not USERNAME or not PASSWORD:
        print("Error: DB_USERNAME and DB_PASSWORD are required when DB_TRUSTED is false.")
        sys.exit(2)
    CONN_STR = base_conn + f"UID={USERNAME};PWD={PASSWORD};"

# Connection string that explicitly targets the application database (used for CREATE/ALTER PROCEDURE)
if TRUSTED:
    CONN_STR_DB = base_conn + f"DATABASE={DATABASE};Trusted_Connection=yes;"
else:
    CONN_STR_DB = base_conn + f"DATABASE={DATABASE};UID={USERNAME};PWD={PASSWORD};"

# Very simple batch splitter on GO lines (start of line, case-insensitive)
# This suits most SQL Server scripts that separate statements with GO

def split_batches(sql_text: str):
    lines = sql_text.splitlines()
    batches = []
    cur = []
    in_procedure = False

    for line in lines:
        stripped = line.strip().upper()
        
        # Skip empty lines and comments
        if not stripped or stripped.startswith('--'):
            cur.append(line)
            continue

        # Handle GO statements
        if stripped == 'GO':
            if cur:
                batches.append('\n'.join(cur))
                cur = []
            in_procedure = False
            continue

        # Check for CREATE/ALTER PROCEDURE
        if 'CREATE PROCEDURE' in stripped or 'ALTER PROCEDURE' in stripped:
            # If we were already collecting lines and hit a new procedure,
            # save the current batch first
            if cur and not in_procedure:
                batches.append('\n'.join(cur))
                cur = []
            in_procedure = True

        # Add the current line
        cur.append(line)

    # Add any remaining lines as the last batch
    if cur:
        batches.append('\n'.join(cur))

    return [batch.strip() for batch in batches if batch.strip()]


def exec_sql_file(conn, cursor, file_path: Path):
    print(f"Applying {file_path} ...")
    with open(file_path, 'r', encoding='utf-8') as f:
        sql_text = f.read()
    batches = split_batches(sql_text)
    
    for i, batch in enumerate(batches, 1):
        if not batch.strip():
            continue
        # Optionally show a short preview of the batch about to run when VERBOSE is enabled
        if VERBOSE:
            first_non_comment = ''
            for line in batch.splitlines():
                s = line.strip()
                if not s or s.startswith('--'):
                    continue
                first_non_comment = s
                break
            print(f"Executing batch #{i}: {first_non_comment[:120]}")
            # Optionally print current DB context when VERBOSE
            try:
                cursor.execute("SELECT DB_NAME();")
                dbname = cursor.fetchone()[0]
            except Exception:
                dbname = '<unknown>'
            print(f" Current DB: {dbname}")
        try:
            # Handle USE database statement separately
            up = batch.upper()
            # Run database-level statements with autocommit (ALTER DATABASE / CREATE DATABASE / DROP DATABASE)
            if 'ALTER DATABASE' in up or 'CREATE DATABASE' in up or 'DROP DATABASE' in up:
                # Use a temporary autocommit connection for database-level operations
                temp_conn = pyodbc.connect(CONN_STR, autocommit=True)
                try:
                    temp_cursor = temp_conn.cursor()
                    temp_cursor.execute(batch)
                    temp_cursor.close()
                finally:
                    try:
                        temp_conn.close()
                    except Exception:
                        pass
                continue

            if batch.upper().startswith('USE '):
                cursor.execute(batch)
                continue

            # For stored procedures and other statements
            # If this batch creates or alters a stored procedure, run it with autocommit
            if 'CREATE PROCEDURE' in up or 'ALTER PROCEDURE' in up or 'CREATE OR ALTER PROCEDURE' in up:
                # Use a connection that includes the target database so the procedure is created in the correct DB
                temp_conn = pyodbc.connect(CONN_STR_DB, autocommit=True)
                try:
                    temp_cursor = temp_conn.cursor()
                    temp_cursor.execute(batch)
                    temp_cursor.close()
                finally:
                    try:
                        temp_conn.close()
                    except Exception:
                        pass
            else:
                cursor.execute(batch)
        except pyodbc.ProgrammingError as e:
            err_text = str(e)

            # Helper: try to extract the object name from a CREATE/ALTER statement
            def extract_object_name(batch_text: str):
                first = ''
                for line in batch_text.splitlines():
                    l = line.strip()
                    if not l or l.startswith('--'):
                        continue
                    first = l
                    break
                up = first.upper()
                # common forms: CREATE TABLE dbo.name, CREATE OR ALTER PROCEDURE dbo.name, CREATE PROCEDURE name
                tokens = up.split()
                if len(tokens) >= 3 and tokens[0] == 'CREATE':
                    # tokens[1] could be 'OR' (CREATE OR ALTER) or object type
                    if tokens[1] == 'OR' and len(tokens) >= 5 and tokens[2] == 'ALTER':
                        # CREATE OR ALTER <TYPE> <name>
                        name_token = tokens[4]
                    else:
                        name_token = tokens[2]
                    # remove possible schema qualifier and brackets
                    return name_token.strip('[]').split('.')[-1]
                if len(tokens) >= 4 and tokens[0] == 'CREATE' and tokens[1] == 'OR' and tokens[2] == 'ALTER':
                    return tokens[3].strip('[]').split('.')[-1]
                # fallback: return first non-empty line truncated
                return (first[:80] + '...') if first else ''

            obj_name = extract_object_name(batch)

            # Detect common SQL Server "already exists" indicators
            already_indicators = [
                '(2714)',
                'there is already',
                'already exists',
                'object already exists',
            ]

            if any(ind.lower() in err_text.lower() for ind in already_indicators):
                obj_info = f" (object: {obj_name})" if obj_name else ''
                print(f"Note: Object already exists in batch #{i}{obj_info}, skipping...")
                continue

            # Fall back to previous behavior: show full error and fail
            print(f"\nError executing SQL batch #{i} in {file_path}:")
            print(f"Error message: {err_text}")
            print("\nFailed batch:")
            print(batch)
            print("\nBatch starts at line:", sum(1 for b in batches[:i-1] for line in b.splitlines()) + 1)
            raise


def main():
    if len(sys.argv) < 2:
        print("Usage: python backend/scripts/apply_sql.py <path_to_sql_file> [more.sql ...]")
        print("Examples:")
        print("  python backend/scripts/apply_sql.py backend/database/init_database.sql")
        print("  python backend/scripts/apply_sql.py backend/database/init_database.sql backend/database/database.sql backend/database/stored_procedures.sql")
        sys.exit(1)

    # Support an optional --verbose flag (or APPLY_SQL_VERBOSE env var) to enable per-batch logging
    args = sys.argv[1:]
    verbose = False
    if '--verbose' in args:
        verbose = True
        args = [a for a in args if a != '--verbose']
    if os.getenv('APPLY_SQL_VERBOSE', '').lower() in ('1', 'true', 'yes'):
        verbose = True

    # set module-level flag
    global VERBOSE
    VERBOSE = verbose

    files = [Path(p) for p in args]
    for p in files:
        if not p.exists():
            print(f"Error: File not found: {p}")
            sys.exit(3)

    # Connect and run all files in order
    conn = pyodbc.connect(CONN_STR)
    try:
        cursor = conn.cursor()
        for p in files:
            exec_sql_file(conn, cursor, p)
            conn.commit()
        print("All SQL scripts applied successfully.")
    finally:
        try:
            cursor.close()
        except Exception:
            pass
        conn.close()


if __name__ == '__main__':
    main()
