import os
import sys
import pyodbc
from pathlib import Path

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
base_conn = f"DRIVER={{{DRIVER}}};SERVER={server};DATABASE={DATABASE};"
if TRUSTED:
    CONN_STR = base_conn + "Trusted_Connection=yes;"
else:
    if not USERNAME or not PASSWORD:
        print("Error: DB_USERNAME and DB_PASSWORD are required when DB_TRUSTED is false.")
        sys.exit(2)
    CONN_STR = base_conn + f"UID={USERNAME};PWD={PASSWORD};"

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


def exec_sql_file(cursor, file_path: Path):
    print(f"Applying {file_path} ...")
    with open(file_path, 'r', encoding='utf-8') as f:
        sql_text = f.read()
    batches = split_batches(sql_text)
    
    for i, batch in enumerate(batches, 1):
        if not batch.strip():
            continue
        try:
            # Handle USE database statement separately
            if batch.upper().startswith('USE '):
                cursor.execute(batch)
                continue

            # For stored procedures and other statements
            cursor.execute(batch)
        except pyodbc.ProgrammingError as e:
            error_code = str(e).split('[')[1].split(']')[0] if '[' in str(e) else None
            
            # Object already exists (table, procedure, etc)
            if error_code in ['42S01', '42S02']:
                print(f"Note: Object already exists in batch #{i}, skipping...")
                continue
                
            print(f"\nError executing SQL batch #{i} in {file_path}:")
            print(f"Error message: {str(e)}")
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

    files = [Path(p) for p in sys.argv[1:]]
    for p in files:
        if not p.exists():
            print(f"Error: File not found: {p}")
            sys.exit(3)

    # Connect and run all files in order
    conn = pyodbc.connect(CONN_STR)
    try:
        cursor = conn.cursor()
        for p in files:
            exec_sql_file(cursor, p)
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
