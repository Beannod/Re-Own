import pyodbc

try:
    conn = pyodbc.connect(
        'DRIVER={ODBC Driver 17 for SQL Server};'
        'SERVER=127.0.0.1\\SQLEXPRESS;'
        'DATABASE=property_manager_db;'
        'Trusted_Connection=yes;'
    )
    cursor = conn.cursor()
    
    # Check if deposit_amount column exists
    cursor.execute("SELECT COL_LENGTH('properties', 'deposit_amount')")
    result = cursor.fetchone()
    has_deposit_col = result[0] is not None if result else False
    
    if not has_deposit_col:
        print('Adding deposit_amount column to properties table...')
        cursor.execute('ALTER TABLE properties ADD deposit_amount FLOAT NULL')
        conn.commit()
        print('Column added successfully!')
    else:
        print('deposit_amount column already exists')
    
    # Also list all columns to verify
    cursor.execute("SELECT COLUMN_NAME FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = 'properties' ORDER BY ORDINAL_POSITION")
    columns = cursor.fetchall()
    print('Current properties table columns:')
    for col in columns:
        print(f'  - {col[0]}')
    
    conn.close()
    
except Exception as e:
    print(f'Database error: {e}')