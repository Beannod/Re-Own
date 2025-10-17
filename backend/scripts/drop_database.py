import os
import sys
import pyodbc

# Connection string for master database
DRIVER = os.getenv("DB_DRIVER", "ODBC Driver 17 for SQL Server")
SERVER = os.getenv("DB_SERVER", ".\\SQLEXPRESS")
PORT = os.getenv("DB_PORT")
USERNAME = os.getenv("DB_USERNAME")
PASSWORD = os.getenv("DB_PASSWORD")
TRUSTED = os.getenv("DB_TRUSTED", "true").lower() in ("1", "true", "yes")

server = f"{SERVER}{',' + PORT if PORT else ''}"
base_conn = f"DRIVER={{{DRIVER}}};SERVER={server};DATABASE=master;"
if TRUSTED:
    CONN_STR = base_conn + "Trusted_Connection=yes;"
else:
    if not USERNAME or not PASSWORD:
        print("Error: DB_USERNAME and DB_PASSWORD are required when DB_TRUSTED is false.")
        sys.exit(2)
    CONN_STR = base_conn + f"UID={USERNAME};PWD={PASSWORD};"

try:
    # Connect to master database
    conn = pyodbc.connect(CONN_STR, autocommit=True)
    cursor = conn.cursor()
    
    # Check if database exists
    cursor.execute("SELECT COUNT(*) FROM sys.databases WHERE name = 'property_manager_db'")
    if cursor.fetchone()[0] > 0:
        print("Dropping existing database...")
        # Force close existing connections
        cursor.execute("""
            ALTER DATABASE property_manager_db SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
            DROP DATABASE property_manager_db;
        """)
        print("Database dropped successfully.")
    else:
        print("Database does not exist.")
    
except Exception as e:
    print(f"Error: {str(e)}")
    sys.exit(1)
finally:
    if 'conn' in locals():
        conn.close()