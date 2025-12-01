-- Bulk Test Data - Dynamic Insertion with CTEs
USE property_manager_db;
GO

DELETE FROM dbo.lease_invitations WHERE created_at >= DATEADD(MONTH, -1, GETDATE());
DELETE FROM dbo.payments WHERE reference_number LIKE 'PAY-%';
DELETE FROM dbo.utilities WHERE reading_date >= DATEADD(YEAR, -1, GETDATE());
DELETE FROM dbo.leases WHERE YEAR(start_date) >= 2024;
DELETE FROM dbo.properties WHERE address LIKE '%Test Street%';
DELETE FROM dbo.users WHERE email LIKE '%test%' OR email LIKE 'admin%' OR email LIKE 'owner%' OR email LIKE 'renter%';
GO

-- Insert Reference Data
INSERT INTO dbo.property_statuses (status_name, description, is_active, created_at)
SELECT v.status_name, v.description, v.is_active, v.created_at
FROM (VALUES
    ('Available','Property is available for rent', 1, GETDATE()),
    ('Occupied','Property is currently occupied', 1, GETDATE()),
    ('Under Maintenance','Property is under maintenance', 1, GETDATE()),
    ('Vacant','Property is vacant', 1, GETDATE()),
    ('Rented','Property is rented out', 1, GETDATE()),
    ('Maintenance','Property requires maintenance', 1, GETDATE())
) AS v(status_name, description, is_active, created_at)
WHERE NOT EXISTS (SELECT 1 FROM dbo.property_statuses p WHERE p.status_name = v.status_name);

INSERT INTO dbo.property_types (type_name, description, is_active, created_at)
SELECT v.type_name, v.description, v.is_active, v.created_at
FROM (VALUES
    ('Apartment','Multi-unit residential building',1,GETDATE()),
    ('House','A standalone residential building',1,GETDATE()),
    ('Condo','Condominium unit',1,GETDATE()),
    ('Townhouse','Townhouse unit',1,GETDATE()),
    ('Studio','Combined living and sleeping space',1,GETDATE())
) AS v(type_name, description, is_active, created_at)
WHERE NOT EXISTS (SELECT 1 FROM dbo.property_types t WHERE t.type_name = v.type_name);

INSERT INTO dbo.payment_types (type_name, description, is_active, created_at)
SELECT v.type_name, v.description, v.is_active, v.created_at
FROM (VALUES
    ('Rent','Regular rental payment',1,GETDATE()),
    ('Deposit','Security deposit',1,GETDATE()),
    ('Utility','Utility payment',1,GETDATE())
) AS v(type_name, description, is_active, created_at)
WHERE NOT EXISTS (SELECT 1 FROM dbo.payment_types pt WHERE pt.type_name = v.type_name);

INSERT INTO dbo.payment_methods (method_name, description, is_active, created_at)
SELECT v.method_name, v.description, v.is_active, v.created_at
FROM (VALUES
    ('Bank Transfer','Bank transfer/wire',1,GETDATE()),
    ('Cash','Cash payment',1,GETDATE()),
    ('Card','Credit/Debit card payment',1,GETDATE())
) AS v(method_name, description, is_active, created_at)
WHERE NOT EXISTS (SELECT 1 FROM dbo.payment_methods pm WHERE pm.method_name = v.method_name);

INSERT INTO dbo.payment_statuses (status_name, description, is_active, created_at)
SELECT v.status_name, v.description, v.is_active, v.created_at
FROM (VALUES
    ('Pending','Payment is pending',1,GETDATE()),
    ('Completed','Payment is completed',1,GETDATE()),
    ('Failed','Payment has failed',1,GETDATE())
) AS v(status_name, description, is_active, created_at)
WHERE NOT EXISTS (SELECT 1 FROM dbo.payment_statuses ps WHERE ps.status_name = v.status_name);

PRINT 'Inserted reference data';
GO

-- Insert 150 Users
WITH n(x) AS (SELECT 1 UNION ALL SELECT x+1 FROM n WHERE x < 150)
INSERT INTO dbo.users (email, username, hashed_password, full_name, role, is_active, created_at)
SELECT 
    CASE WHEN x <= 50 THEN 'admin' WHEN x <= 100 THEN 'owner' ELSE 'renter' END + CAST(((x-1) % 50)+1 AS NVARCHAR(10)) + '@example.com',
    CASE WHEN x <= 50 THEN 'admin' WHEN x <= 100 THEN 'owner' ELSE 'renter' END + CAST(((x-1) % 50)+1 AS NVARCHAR(10)),
    '$pbkdf2-sha256$29000$test1234567890123456',
    CASE WHEN x <= 50 THEN 'Admin' WHEN x <= 100 THEN 'Owner' ELSE 'Renter' END + ' ' + CAST(((x-1) % 50)+1 AS NVARCHAR(10)),
    CASE WHEN x <= 50 THEN 'admin' WHEN x <= 100 THEN 'owner' ELSE 'renter' END,
    1, GETDATE()
FROM n OPTION (MAXRECURSION 200);

PRINT 'Inserted 150 users';
GO

-- Insert 120 Properties
DECLARE @owner_id INT;
SELECT TOP 1 @owner_id = id FROM dbo.users WHERE role = 'owner';
WITH n(x) AS (SELECT 1 UNION ALL SELECT x+1 FROM n WHERE x < 120)
INSERT INTO dbo.properties (owner_id, title, description, address, city, state, zip_code, country, property_type, status, monthly_rent, security_deposit, available_from, created_at)
SELECT 
    @owner_id,
    'Property ' + CAST(x AS NVARCHAR(10)),
    'Test property',
    CAST(x AS NVARCHAR(10)) + ' Test Street',
    'TestCity',
    'TS',
    '12345',
    'USA',
    CASE (x % 5) WHEN 0 THEN 'Apartment' WHEN 1 THEN 'House' WHEN 2 THEN 'Condo' WHEN 3 THEN 'Townhouse' ELSE 'Studio' END,
    CASE (x % 3) WHEN 0 THEN 'Available' WHEN 1 THEN 'Vacant' ELSE 'Occupied' END,
    1000 + (x * 50),
    1000 + (x * 50),
    DATEADD(DAY, x, GETDATE()),
    GETDATE()
FROM n OPTION (MAXRECURSION 200);

PRINT 'Inserted 120 properties';
GO

-- Insert 110 Leases
WITH n(x) AS (SELECT 1 UNION ALL SELECT x+1 FROM n WHERE x < 110)
INSERT INTO dbo.leases (property_id, tenant_id, start_date, end_date, monthly_rent, security_deposit, is_active, created_at)
SELECT 
    (SELECT MIN(id) + (x % 120) FROM dbo.properties WHERE address LIKE '%Test Street%'),
    (SELECT MIN(id) + (x % 50) FROM dbo.users WHERE role = 'renter'),
    DATEADD(DAY, x, GETDATE()),
    DATEADD(DAY, x + 365, GETDATE()),
    1000 + (x * 50),
    2000 + (x * 50),
    1,
    GETDATE()
FROM n OPTION (MAXRECURSION 200);

PRINT 'Inserted 110 leases';
GO

-- Insert 150 Payments
WITH n(x) AS (SELECT 1 UNION ALL SELECT x+1 FROM n WHERE x < 150)
INSERT INTO dbo.payments (lease_id, property_id, tenant_id, payment_type, payment_method, amount, payment_date, payment_status, reference_number, created_at)
SELECT 
    (SELECT MIN(id) + (x % (SELECT COUNT(*) FROM dbo.leases)) FROM dbo.leases),
    (SELECT MIN(id) + (x % (SELECT COUNT(*) FROM dbo.properties WHERE address LIKE '%Test Street%')) FROM dbo.properties WHERE address LIKE '%Test Street%'),
    (SELECT MIN(id) + (x % 50) FROM dbo.users WHERE role = 'renter'),
    CASE (x % 3) WHEN 0 THEN 'Rent' WHEN 1 THEN 'Deposit' ELSE 'Utility' END,
    'Bank Transfer',
    1000 + (x * 10),
    DATEADD(DAY, x, GETDATE()),
    CASE (x % 3) WHEN 0 THEN 'Completed' WHEN 1 THEN 'Pending' ELSE 'Failed' END,
    'PAY-' + CAST(YEAR(GETDATE()) AS NVARCHAR(4)) + '-' + CAST(x AS NVARCHAR(10)),
    GETDATE()
FROM n OPTION (MAXRECURSION 200);

PRINT 'Inserted 150 payments';
GO

-- Insert 130 Utilities
WITH n(x) AS (SELECT 1 UNION ALL SELECT x+1 FROM n WHERE x < 130)
INSERT INTO dbo.utilities (lease_id, property_id, utility_type, reading_date, reading_value, rate_at_reading, amount, status, created_at)
SELECT 
    (SELECT MIN(id) + (x % (SELECT COUNT(*) FROM dbo.leases)) FROM dbo.leases),
    (SELECT MIN(id) + (x % (SELECT COUNT(*) FROM dbo.properties WHERE address LIKE '%Test Street%')) FROM dbo.properties WHERE address LIKE '%Test Street%'),
    CASE (x % 5) WHEN 0 THEN 'Electricity' WHEN 1 THEN 'Water' WHEN 2 THEN 'Gas' WHEN 3 THEN 'Internet' ELSE 'Trash' END,
    DATEADD(DAY, x, GETDATE()),
    100 + (x * 1.5),
    CASE (x % 5) WHEN 0 THEN 0.12 WHEN 1 THEN 0.08 WHEN 2 THEN 0.15 WHEN 3 THEN 0.00 ELSE 0.05 END,
    (100 + (x * 1.5)) * CASE (x % 5) WHEN 0 THEN 0.12 WHEN 1 THEN 0.08 WHEN 2 THEN 0.15 WHEN 3 THEN 0.00 ELSE 0.05 END,
    CASE (x % 3) WHEN 0 THEN 'Completed' WHEN 1 THEN 'Pending' ELSE 'Billed' END,
    GETDATE()
FROM n OPTION (MAXRECURSION 200);

PRINT 'Inserted 130 utilities';
GO

-- Insert 100 Lease Invitations
WITH n(x) AS (SELECT 1 UNION ALL SELECT x+1 FROM n WHERE x < 100)
INSERT INTO dbo.lease_invitations (property_id, tenant_email, invitation_code, is_accepted, expires_at, created_at)
SELECT 
    (SELECT MIN(id) + (x % (SELECT COUNT(*) FROM dbo.properties WHERE address LIKE '%Test Street%')) FROM dbo.properties WHERE address LIKE '%Test Street%'),
    (SELECT MIN(email) FROM dbo.users WHERE role = 'renter' AND id = (SELECT MIN(id) + (x % 50) FROM dbo.users WHERE role = 'renter')),
    REPLACE(CONVERT(NVARCHAR(36), NEWID()), '-', ''),
    0,
    DATEADD(DAY, 14, GETDATE()),
    GETDATE()
FROM n OPTION (MAXRECURSION 200);

PRINT 'Inserted 100 lease invitations';
GO

-- Summary
PRINT '';
PRINT '========== DATA SUMMARY ==========';
SELECT 'Users' TableName, COUNT(*) RecordCount FROM dbo.users UNION ALL
SELECT 'Properties', COUNT(*) FROM dbo.properties UNION ALL
SELECT 'Leases', COUNT(*) FROM dbo.leases UNION ALL
SELECT 'Payments', COUNT(*) FROM dbo.payments UNION ALL
SELECT 'Utilities', COUNT(*) FROM dbo.utilities UNION ALL
SELECT 'Lease Invitations', COUNT(*) FROM dbo.lease_invitations;
PRINT '==================================';
GO
