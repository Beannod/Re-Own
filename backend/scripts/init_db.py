import pyodbc
import os
import re

master_db = "master"
target_db = os.getenv("DB_NAME", "property_manager_db")
driver = os.getenv("DB_DRIVER", "ODBC Driver 17 for SQL Server")
server = os.getenv("DB_SERVER", r".\\SQLEXPRESS")
port = os.getenv("DB_PORT")
trusted = os.getenv("DB_TRUSTED", "true").lower() in ("1", "true", "yes")
username = os.getenv("DB_USERNAME")
password = os.getenv("DB_PASSWORD")

server_with_port = f"{server}{',' + port if port else ''}"

def build_conn_str(db_name: str) -> str:
    driver_seg = f"DRIVER={{{{ {driver} }}}};".replace("{{ ", "{").replace(" }}}}", "}")
    server_seg = f"SERVER={server_with_port};"
    db_seg = f"DATABASE={db_name};"
    if trusted:
        auth_seg = "Trusted_Connection=yes;"
    else:
        auth_seg = f"UID={username};PWD={password};"
    return driver_seg + server_seg + db_seg + auth_seg

MASTER_CONN_STR = build_conn_str(master_db)
DB_CONN_STR = build_conn_str(target_db)

def exec_sql_file(conn, file_path: str):
    print(f"Executing SQL file: {file_path}")
    with open(file_path, 'r', encoding='utf-8') as f:
        sql = f.read()
    # Split on GO batch separators (must be alone on a line, case-insensitive)
    batches = [b.strip() for b in re.split(r"(?im)^\s*GO\s*;?\s*$", sql) if b.strip()]
    cur = conn.cursor()
    for batch in batches:
        cur.execute(batch)
        # consume any possible result sets to avoid 'Results pending' errors
        try:
            while cur.nextset():
                pass
        except pyodbc.ProgrammingError:
            pass
    conn.commit()
    cur.close()

if __name__ == "__main__":
    print("Connecting to master using:", MASTER_CONN_STR)
    try:
        conn = pyodbc.connect(MASTER_CONN_STR, autocommit=True)
        cur = conn.cursor()
        cur.execute(f"IF DB_ID('{target_db}') IS NULL CREATE DATABASE {target_db};")
        print("Database check/create executed successfully.")
        cur.close()
        conn.close()
    except Exception as e:
        print("ERROR connecting or creating database:", e)
        raise

    # Connect to target DB and run schema + stored procedures
    print("Connecting to target DB using:", DB_CONN_STR)
    conn = pyodbc.connect(DB_CONN_STR, autocommit=True)
    base_dir = os.path.abspath(os.path.join(os.path.dirname(__file__), '..', 'database'))
    schema_sql = os.path.join(base_dir, 'database.sql')
    init_sql = os.path.join(base_dir, 'init_database.sql')
    sprocs_sql = os.path.join(base_dir, 'stored_procedures.sql')

    if os.path.exists(schema_sql):
        exec_sql_file(conn, schema_sql)
    else:
        print(f"Schema file not found: {schema_sql}")

    # Execute the original init script as well (contains sp_GetUserByEmail, table creates)
    if os.path.exists(init_sql):
        exec_sql_file(conn, init_sql)
    else:
        print(f"Init file not found: {init_sql}")

    if os.path.exists(sprocs_sql):
        exec_sql_file(conn, sprocs_sql)
    else:
        print(f"Stored procedures file not found: {sprocs_sql}")

    conn.close()
    print("Database initialized successfully.")
