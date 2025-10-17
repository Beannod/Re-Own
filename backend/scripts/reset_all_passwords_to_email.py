
import pyodbc
from passlib.hash import pbkdf2_sha256

# Connection string for named pipe
conn_str = r"DRIVER={ODBC Driver 17 for SQL Server};SERVER=np:\\.\pipe\MSSQL$SQLEXPRESS\sql\query;DATABASE=property_manager_db;Trusted_Connection=yes;"

with pyodbc.connect(conn_str) as conn:
    cursor = conn.cursor()
    cursor.execute("SELECT id, email FROM users")
    users = cursor.fetchall()
    for user in users:
        user_id = user[0]
        email = user[1]
        hashed_password = pbkdf2_sha256.hash(email)
        cursor.execute("UPDATE users SET hashed_password = ? WHERE id = ?", hashed_password, user_id)
        print(f"Password for {email} reset to their own email address.")
    conn.commit()
print("All user passwords have been reset to their own email address.")
