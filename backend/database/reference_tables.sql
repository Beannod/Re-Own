USE property_manager_db;
GO

-- Create reference tables for all lookup values

-- Property Status Reference
DROP TABLE IF EXISTS #TempStatusValues;
CREATE TABLE #TempStatusValues (
    status_name NVARCHAR(50),
    description NVARCHAR(200)
);

INSERT INTO #TempStatusValues (status_name, description) VALUES 
    ('Available', 'Property is available for rent'),
    ('Occupied', 'Property is currently occupied'),
    ('Under Maintenance', 'Property is under maintenance'),
    ('vacant', 'Property is vacant'),
    ('rented', 'Property is rented out'),
    ('maintenance', 'Property requires maintenance');

IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[property_statuses]') AND type in (N'U'))
BEGIN
    CREATE TABLE property_statuses (
        id INT IDENTITY(1,1) PRIMARY KEY,
        status_name NVARCHAR(50) NOT NULL UNIQUE,
        description NVARCHAR(200),
        is_active BIT DEFAULT 1,
        created_at DATETIME2 DEFAULT GETDATE(),
        updated_at DATETIME2
    );
    
    INSERT INTO property_statuses (status_name, description)
    SELECT status_name, description FROM #TempStatusValues;
END
ELSE
BEGIN
    MERGE property_statuses AS target
    USING #TempStatusValues AS source
    ON (target.status_name = source.status_name)
    WHEN NOT MATCHED BY target THEN
        INSERT (status_name, description)
        VALUES (source.status_name, source.description)
    WHEN MATCHED THEN
        UPDATE SET description = source.description;
END;

DROP TABLE #TempStatusValues;
GO
END;

-- Property Types Reference
-- Property Types Reference
DROP TABLE IF EXISTS #TempPropertyTypes;
CREATE TABLE #TempPropertyTypes (
    type_name NVARCHAR(50),
    description NVARCHAR(200)
);

INSERT INTO #TempPropertyTypes (type_name, description) VALUES 
    ('Flat', 'An individual unit in an apartment building'),
    ('House', 'A standalone residential building'),
    ('Commercial', 'Property for business use'),
    ('Land', 'Undeveloped property'),
    ('Room', 'Single room rental'),
    ('Apartment', 'Multi-unit residential building'),
    ('Studio', 'Combined living and sleeping space'),
    ('Villa', 'Luxury standalone house');

IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[property_types]') AND type in (N'U'))
BEGIN
    CREATE TABLE property_types (
        id INT IDENTITY(1,1) PRIMARY KEY,
        type_name NVARCHAR(50) NOT NULL UNIQUE,
        description NVARCHAR(200),
        is_active BIT DEFAULT 1,
        created_at DATETIME2 DEFAULT GETDATE(),
        updated_at DATETIME2
    );
    
    INSERT INTO property_types (type_name, description)
    SELECT type_name, description FROM #TempPropertyTypes;
END
ELSE
BEGIN
    MERGE property_types AS target
    USING #TempPropertyTypes AS source
    ON (target.type_name = source.type_name)
    WHEN NOT MATCHED BY target THEN
        INSERT (type_name, description)
        VALUES (source.type_name, source.description)
    WHEN MATCHED THEN
        UPDATE SET description = source.description;
END;

DROP TABLE #TempPropertyTypes;
END;

-- Payment Types Reference
-- Payment Types Reference
DROP TABLE IF EXISTS #TempPaymentTypes;
CREATE TABLE #TempPaymentTypes (
    type_name NVARCHAR(50),
    description NVARCHAR(200)
);

INSERT INTO #TempPaymentTypes (type_name, description) VALUES 
    ('rent', 'Regular rental payment'),
    ('deposit', 'Security deposit'),
    ('utility', 'Utility payment');

IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[payment_types]') AND type in (N'U'))
BEGIN
    CREATE TABLE payment_types (
        id INT IDENTITY(1,1) PRIMARY KEY,
        type_name NVARCHAR(50) NOT NULL UNIQUE,
        description NVARCHAR(200),
        is_active BIT DEFAULT 1,
        created_at DATETIME2 DEFAULT GETDATE(),
        updated_at DATETIME2
    );
    
    INSERT INTO payment_types (type_name, description)
    SELECT type_name, description FROM #TempPaymentTypes;
END
ELSE
BEGIN
    MERGE payment_types AS target
    USING #TempPaymentTypes AS source
    ON (target.type_name = source.type_name)
    WHEN NOT MATCHED BY target THEN
        INSERT (type_name, description)
        VALUES (source.type_name, source.description)
    WHEN MATCHED THEN
        UPDATE SET description = source.description;
END;

DROP TABLE #TempPaymentTypes;
END;

-- Payment Methods Reference
-- Payment Methods Reference
DROP TABLE IF EXISTS #TempPaymentMethods;
CREATE TABLE #TempPaymentMethods (
    method_name NVARCHAR(50),
    description NVARCHAR(200)
);

INSERT INTO #TempPaymentMethods (method_name, description) VALUES 
    ('cash', 'Cash payment'),
    ('bank_transfer', 'Bank transfer/wire'),
    ('card', 'Credit/Debit card payment');

IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[payment_methods]') AND type in (N'U'))
BEGIN
    CREATE TABLE payment_methods (
        id INT IDENTITY(1,1) PRIMARY KEY,
        method_name NVARCHAR(50) NOT NULL UNIQUE,
        description NVARCHAR(200),
        is_active BIT DEFAULT 1,
        created_at DATETIME2 DEFAULT GETDATE(),
        updated_at DATETIME2
    );
    
    INSERT INTO payment_methods (method_name, description)
    SELECT method_name, description FROM #TempPaymentMethods;
END
ELSE
BEGIN
    MERGE payment_methods AS target
    USING #TempPaymentMethods AS source
    ON (target.method_name = source.method_name)
    WHEN NOT MATCHED BY target THEN
        INSERT (method_name, description)
        VALUES (source.method_name, source.description)
    WHEN MATCHED THEN
        UPDATE SET description = source.description;
END;

DROP TABLE #TempPaymentMethods;
END;

-- Payment Status Reference
-- Payment Statuses Reference
DROP TABLE IF EXISTS #TempPaymentStatuses;
CREATE TABLE #TempPaymentStatuses (
    status_name NVARCHAR(50),
    description NVARCHAR(200)
);

INSERT INTO #TempPaymentStatuses (status_name, description) VALUES 
    ('pending', 'Payment is pending'),
    ('completed', 'Payment is completed'),
    ('failed', 'Payment has failed');

IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[payment_statuses]') AND type in (N'U'))
BEGIN
    CREATE TABLE payment_statuses (
        id INT IDENTITY(1,1) PRIMARY KEY,
        status_name NVARCHAR(50) NOT NULL UNIQUE,
        description NVARCHAR(200),
        is_active BIT DEFAULT 1,
        created_at DATETIME2 DEFAULT GETDATE(),
        updated_at DATETIME2
    );
    
    INSERT INTO payment_statuses (status_name, description)
    SELECT status_name, description FROM #TempPaymentStatuses;
END
ELSE
BEGIN
    MERGE payment_statuses AS target
    USING #TempPaymentStatuses AS source
    ON (target.status_name = source.status_name)
    WHEN NOT MATCHED BY target THEN
        INSERT (status_name, description)
        VALUES (source.status_name, source.description)
    WHEN MATCHED THEN
        UPDATE SET description = source.description;
END;

DROP TABLE #TempPaymentStatuses;
END;

-- Update foreign key constraints to reference the new tables
ALTER TABLE properties DROP CONSTRAINT IF EXISTS CHK_properties_status;
ALTER TABLE properties ADD CONSTRAINT FK_properties_status 
    FOREIGN KEY (status) REFERENCES property_statuses(status_name);

-- Add constraints to the payments table
ALTER TABLE payments ADD CONSTRAINT FK_payments_payment_type 
    FOREIGN KEY (payment_type) REFERENCES payment_types(type_name);
ALTER TABLE payments ADD CONSTRAINT FK_payments_payment_method 
    FOREIGN KEY (payment_method) REFERENCES payment_methods(method_name);
ALTER TABLE payments ADD CONSTRAINT FK_payments_payment_status 
    FOREIGN KEY (payment_status) REFERENCES payment_statuses(status_name);

GO