#!/usr/bin/env python3
import pyodbc
import os

DRIVER = os.getenv("DB_DRIVER", "ODBC Driver 17 for SQL Server")
SERVER = os.getenv("DB_SERVER", ".\\SQLEXPRESS")
DATABASE = os.getenv("DB_NAME", "property_manager_db")
PORT = os.getenv("DB_PORT")
USERNAME = os.getenv("DB_USERNAME")
PASSWORD = os.getenv("DB_PASSWORD")
TRUSTED = os.getenv("DB_TRUSTED", "true").lower() in ("1", "true", "yes")

server = f"{SERVER}{',' + PORT if PORT else ''}"
base_conn = f"DRIVER={{{DRIVER}}};SERVER={server};"
if TRUSTED:
    CONN_STR = base_conn + f"DATABASE={DATABASE};Trusted_Connection=yes;"
else:
    if not USERNAME or not PASSWORD:
        print("Error: DB_USERNAME and DB_PASSWORD are required when DB_TRUSTED is false.")
        exit(2)
    CONN_STR = base_conn + f"DATABASE={DATABASE};UID={USERNAME};PWD={PASSWORD};"

try:
    conn = pyodbc.connect(CONN_STR)
    cursor = conn.cursor()
    
    # Test sp_CreateLeaseInvitation with correct parameters
    print("Testing sp_CreateLeaseInvitation with parameters:")
    print("  OwnerId: 314")
    print("  RenterId: 315")
    print("  PropertyId: 102")
    print("  StartDate: 2025-10-28")
    print("  RentAmount: 100")
    print("  DepositAmount: 10")
    print()
    
    cursor.execute("""
        EXEC sp_CreateLeaseInvitation 
            @OwnerId=314,
            @RenterId=315,
            @PropertyId=102,
            @StartDate='2025-10-28',
            @RentAmount=100,
            @DepositAmount=10
    """)
    
    result = cursor.fetchone()
    if result:
        print(f"✓ SUCCESS: Invitation created with ID: {result[0]}")
    else:
        print("✓ Procedure executed without error")
    
    conn.close()
    
except Exception as e:
    print(f"✗ ERROR: {e}")
    import traceback
    traceback.print_exc()
