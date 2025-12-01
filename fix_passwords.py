#!/usr/bin/env python
import sys
sys.path.insert(0, 'd:\\Re-Own')

from backend.app.core.security import pwd_context
import pyodbc

# Connect to database
conn_str = r'Driver={ODBC Driver 17 for SQL Server};Server=.\SQLEXPRESS;Database=property_manager_db;Trusted_Connection=yes;'
conn = pyodbc.connect(conn_str)
cursor = conn.cursor()

# Generate proper hash for password "test"
proper_hash = pwd_context.hash("test")
print(f"Generated hash: {proper_hash}")

# Update all test users with proper password
cursor.execute(f"""
    UPDATE dbo.users 
    SET hashed_password = '{proper_hash}'
    WHERE email LIKE 'admin%' OR email LIKE 'owner%' OR email LIKE 'renter%'
""")

conn.commit()
print(f"Updated {cursor.rowcount} user records")
cursor.close()
conn.close()
