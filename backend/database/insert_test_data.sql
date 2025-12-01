-- cleaned_idempotent_seed_using_ids.sql
-- Idempotent seed script for property_manager_db
-- Uses FK IDs for property_type_id and status_id
-- Large dataset (~250 rows) as requested

SET NOCOUNT ON;
USE property_manager_db;
GO

-- Ensure columns exist in their own batch so subsequent batches see them
IF NOT EXISTS (
    SELECT 1 FROM sys.columns
    WHERE object_id = OBJECT_ID('dbo.properties') AND name = 'rent_amount'
)
BEGIN
    ALTER TABLE dbo.properties ADD rent_amount DECIMAL(10,2) NULL;
END

IF NOT EXISTS (
    SELECT 1 FROM sys.columns
    WHERE object_id = OBJECT_ID('dbo.properties') AND name = 'bedrooms'
)
BEGIN
    ALTER TABLE dbo.properties ADD bedrooms INT NULL CONSTRAINT DF_properties_bedrooms DEFAULT 0;
END

IF NOT EXISTS (
    SELECT 1 FROM sys.columns
    WHERE object_id = OBJECT_ID('dbo.properties') AND name = 'bathrooms'
)
BEGIN
    ALTER TABLE dbo.properties ADD bathrooms DECIMAL(10,2) NULL CONSTRAINT DF_properties_bathrooms DEFAULT 0.00;
END

IF NOT EXISTS (
    SELECT 1 FROM sys.columns
    WHERE object_id = OBJECT_ID('dbo.properties') AND name = 'area'
)
BEGIN
    ALTER TABLE dbo.properties ADD area DECIMAL(10,2) NULL CONSTRAINT DF_properties_area DEFAULT 0.00;
END

IF NOT EXISTS (
    SELECT 1 FROM sys.columns
    WHERE object_id = OBJECT_ID('dbo.properties') AND name = 'property_type_id'
)
BEGIN
    ALTER TABLE dbo.properties ADD property_type_id INT NULL;
END

IF NOT EXISTS (
    SELECT 1 FROM sys.columns
    WHERE object_id = OBJECT_ID('dbo.properties') AND name = 'status_id'
)
BEGIN
    ALTER TABLE dbo.properties ADD status_id INT NULL;
END
GO

BEGIN TRY
    BEGIN TRANSACTION;

    

    -- ------------------------------------------------------------------
    -- Reference data (single canonical insert block) -- values are case-consistent
    -- ------------------------------------------------------------------

    -- property_statuses
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

    -- property_types
    INSERT INTO dbo.property_types (type_name, description, is_active, created_at)
    SELECT v.type_name, v.description, v.is_active, v.created_at
    FROM (VALUES
        ('Apartment','Multi-unit residential building',1,GETDATE()),
        ('House','A standalone residential building',1,GETDATE()),
        ('Flat','An individual unit in an apartment building',1,GETDATE()),
        ('Commercial','Property for business use',1,GETDATE()),
        ('Land','Undeveloped property',1,GETDATE()),
        ('Room','Single room rental',1,GETDATE()),
        ('Studio','Combined living and sleeping space',1,GETDATE()),
        ('Villa','Luxury standalone house',1,GETDATE())
    ) AS v(type_name, description, is_active, created_at)
    WHERE NOT EXISTS (SELECT 1 FROM dbo.property_types t WHERE t.type_name = v.type_name);

    -- payment_types
    INSERT INTO dbo.payment_types (type_name, description, is_active, created_at)
    SELECT v.type_name, v.description, v.is_active, v.created_at
    FROM (VALUES
        ('Rent','Regular rental payment',1,GETDATE()),
        ('Deposit','Security deposit',1,GETDATE()),
        ('Utility','Utility payment',1,GETDATE())
    ) AS v(type_name, description, is_active, created_at)
    WHERE NOT EXISTS (SELECT 1 FROM dbo.payment_types pt WHERE pt.type_name = v.type_name);

    -- payment_methods
    INSERT INTO dbo.payment_methods (method_name, description, is_active, created_at)
    SELECT v.method_name, v.description, v.is_active, v.created_at
    FROM (VALUES
        ('Bank Transfer','Bank transfer/wire',1,GETDATE()),
        ('Cash','Cash payment',1,GETDATE()),
        ('Card','Credit/Debit card payment',1,GETDATE())
    ) AS v(method_name, description, is_active, created_at)
    WHERE NOT EXISTS (SELECT 1 FROM dbo.payment_methods pm WHERE pm.method_name = v.method_name);

    -- payment_statuses
    INSERT INTO dbo.payment_statuses (status_name, description, is_active, created_at)
    SELECT v.status_name, v.description, v.is_active, v.created_at
    FROM (VALUES
        ('Pending','Payment is pending',1,GETDATE()),
        ('Completed','Payment is completed',1,GETDATE()),
        ('Failed','Payment has failed',1,GETDATE())
    ) AS v(status_name, description, is_active, created_at)
    WHERE NOT EXISTS (SELECT 1 FROM dbo.payment_statuses ps WHERE ps.status_name = v.status_name);

    -- utilities_base minimal defaults
    IF NOT EXISTS (SELECT 1 FROM dbo.utilities_base WHERE name = 'Electricity')
    BEGIN
        INSERT INTO dbo.utilities_base (name, description, rate_per_unit, unit_name, created_at)
        VALUES ('Electricity','Electricity usage',0.12,'kWh',GETDATE());
    END

    -- ------------------------------------------------------------------
    -- Users (idempotent by email) - create canonical admin/owner/renter
    -- ------------------------------------------------------------------
    IF NOT EXISTS (SELECT 1 FROM dbo.users WHERE email = 'admin@example.com')
    BEGIN
        INSERT INTO dbo.users (email, username, hashed_password, full_name, role, is_active, dark_mode, notification_preferences, created_at)
        VALUES ('admin@example.com','admin1','$pbkdf2-sha256$29000$adminhash','Admin User','admin',1,0,NULL,GETDATE());
    END

    IF NOT EXISTS (SELECT 1 FROM dbo.users WHERE email = 'owner@example.com')
    BEGIN
        INSERT INTO dbo.users (email, username, hashed_password, full_name, role, is_active, created_at)
        VALUES ('owner@example.com','owner1','$pbkdf2-sha256$29000$ownerhash','Olivia Owner','owner',1,GETDATE());
    END

    IF NOT EXISTS (SELECT 1 FROM dbo.users WHERE email = 'renter@example.com')
    BEGIN
        INSERT INTO dbo.users (email, username, hashed_password, full_name, role, is_active, created_at)
        VALUES ('renter@example.com','renter1','$pbkdf2-sha256$29000$renterhash','Robert Renter','renter',1,GETDATE());
    END

    -- ------------------------------------------------------------------
    -- Test login user (idempotent) - use for local login testing
    -- Email: testuser@example.com  Password: (known test password, hashed)
    -- ------------------------------------------------------------------
    IF NOT EXISTS (SELECT 1 FROM dbo.users WHERE email = 'testuser@example.com')
    BEGIN
        INSERT INTO dbo.users (email, username, hashed_password, full_name, role, is_active, created_at)
        VALUES ('testuser@example.com', 'testuser', '$pbkdf2-sha256$29000$testhash', 'Test User', 'renter', 1, GETDATE());
    END

    -- create a simple renter_profile for the test user if the profile table exists and no profile exists
    IF EXISTS (SELECT 1 FROM sys.objects WHERE object_id = OBJECT_ID('dbo.renter_profiles') AND type in ('U'))
    BEGIN
        DECLARE @testUserId INT = (SELECT id FROM dbo.users WHERE email = 'testuser@example.com');
        IF @testUserId IS NOT NULL AND NOT EXISTS (SELECT 1 FROM dbo.renter_profiles rp WHERE rp.user_id = @testUserId)
        BEGIN
            INSERT INTO dbo.renter_profiles (user_id, emergency_contact, phone_number, current_address, employment_info, tenant_notes, created_at)
            VALUES (@testUserId, 'Emergency Contact Test', '9000000123', 'Test Address 1', 'Test Employer', 'Profile for test login user', GETDATE());
        END
    END

    -- ------------------------------------------------------------------
    -- Populate more users to reach ~250 users (idempotent by email)
    -- ------------------------------------------------------------------
    DECLARE @user_counter INT = 4;
    WHILE @user_counter <= 250
    BEGIN
        DECLARE @user_email NVARCHAR(150) = 'user' + CAST(@user_counter AS NVARCHAR(10)) + '@example.com';
        IF NOT EXISTS (SELECT 1 FROM dbo.users WHERE email = @user_email)
        BEGIN
            INSERT INTO dbo.users (email, username, hashed_password, full_name, role, is_active, created_at)
            VALUES (
                @user_email,
                'user' + CAST(@user_counter AS NVARCHAR(10)),
                '$pbkdf2-sha256$29000$dummyhash' + CAST(@user_counter AS NVARCHAR(10)),
                'User ' + CAST(@user_counter AS NVARCHAR(10)),
                CASE WHEN @user_counter % 3 = 0 THEN 'admin' WHEN @user_counter % 3 = 1 THEN 'owner' ELSE 'renter' END,
                1,
                GETDATE()
            );
        END
        SET @user_counter = @user_counter + 1;
    END

    -- ------------------------------------------------------------------
    -- Owner and Renter profiles (idempotent)
    -- ------------------------------------------------------------------
    INSERT INTO dbo.owner_profiles (user_id, company_name, contact_number, address, tax_id, notes, created_at)
    SELECT u.id,
           CONCAT('Owner Company ', u.id),
           '000-000-0000',
           CONCAT('Auto-generated address for owner ', u.id),
           CONCAT('TAX-', u.id),
           'Auto-generated owner profile for testing',
           GETDATE()
    FROM dbo.users u
    WHERE u.role = 'owner'
      AND NOT EXISTS (SELECT 1 FROM dbo.owner_profiles op WHERE op.user_id = u.id);

    INSERT INTO dbo.renter_profiles (user_id, emergency_contact, phone_number, current_address, employment_info, tenant_notes, created_at)
    SELECT u.id,
           CONCAT('Emergency Contact ', u.id),
           CONCAT('9000000', RIGHT('0000' + CAST(u.id AS NVARCHAR(10)), 4)),
           CONCAT('Auto-generated renter address ', u.id),
           CONCAT('Employer ', u.id),
           'Auto-generated renter profile for testing',
           GETDATE()
    FROM dbo.users u
    WHERE u.role = 'renter'
      AND NOT EXISTS (SELECT 1 FROM dbo.renter_profiles rp WHERE rp.user_id = u.id);

    -- ------------------------------------------------------------------
    -- Properties: create at least 250 properties (idempotent by title)
    -- Uses property_type_id and status_id (FK ids)
    -- ------------------------------------------------------------------
    DECLARE @prop_counter INT = 3;
    DECLARE @owner_count INT = (SELECT COUNT(*) FROM dbo.users WHERE role = 'owner');
    IF @owner_count = 0
    BEGIN
        -- ensure a canonical owner exists
        IF NOT EXISTS (SELECT 1 FROM dbo.users WHERE email = 'owner@example.com')
        BEGIN
            INSERT INTO dbo.users (email, username, hashed_password, full_name, role, is_active, created_at)
            VALUES ('owner@example.com', 'owner1', '$pbkdf2-sha256$29000$ownerhash', 'Olivia Owner', 'owner', 1, GETDATE());
        END
        SET @owner_count = (SELECT COUNT(*) FROM dbo.users WHERE role = 'owner');
    END

    WHILE @prop_counter <= 250
    BEGIN
        DECLARE @title NVARCHAR(200) = 'Property ' + CAST(@prop_counter AS NVARCHAR(10));
        IF NOT EXISTS (SELECT 1 FROM dbo.properties WHERE title = @title)
        BEGIN
            DECLARE @owner_index INT = ((@prop_counter - 3) % @owner_count) + 1;
            DECLARE @owner_id INT;
            SELECT @owner_id = id FROM (
                SELECT id, ROW_NUMBER() OVER (ORDER BY id) AS rn FROM dbo.users WHERE role = 'owner'
            ) AS owners WHERE rn = @owner_index;

            DECLARE @city NVARCHAR(100) = CASE WHEN @prop_counter % 5 = 0 THEN 'New York' WHEN @prop_counter % 5 = 1 THEN 'Los Angeles' WHEN @prop_counter % 5 = 2 THEN 'Chicago' WHEN @prop_counter % 5 = 3 THEN 'Houston' ELSE 'Phoenix' END;
            DECLARE @state NVARCHAR(10) = CASE WHEN @prop_counter % 5 = 0 THEN 'NY' WHEN @prop_counter % 5 = 1 THEN 'CA' WHEN @prop_counter % 5 = 2 THEN 'IL' WHEN @prop_counter % 5 = 3 THEN 'TX' ELSE 'AZ' END;
            DECLARE @ptype NVARCHAR(50) = CASE WHEN @prop_counter % 8 = 0 THEN 'Apartment' WHEN @prop_counter % 8 = 1 THEN 'House' WHEN @prop_counter % 8 = 2 THEN 'Flat' WHEN @prop_counter % 8 = 3 THEN 'Commercial' WHEN @prop_counter % 8 = 4 THEN 'Land' WHEN @prop_counter % 8 = 5 THEN 'Room' WHEN @prop_counter % 8 = 6 THEN 'Studio' ELSE 'Villa' END;
            DECLARE @status_name NVARCHAR(50) = CASE WHEN @prop_counter % 6 = 0 THEN 'Available' WHEN @prop_counter % 6 = 1 THEN 'Occupied' WHEN @prop_counter % 6 = 2 THEN 'Under Maintenance' WHEN @prop_counter % 6 = 3 THEN 'Vacant' WHEN @prop_counter % 6 = 4 THEN 'Rented' ELSE 'Maintenance' END;

            DECLARE @ptype_id INT = (SELECT id FROM dbo.property_types WHERE type_name = @ptype);
            DECLARE @status_id INT = (SELECT id FROM dbo.property_statuses WHERE status_name = @status_name);

            INSERT INTO dbo.properties (
                owner_id, title, description, address, city, state, zip_code, country, property_type_id, status_id,
                monthly_rent, security_deposit, available_from, rent_amount, bedrooms, bathrooms, area
            )
            VALUES (
                ISNULL(@owner_id, (SELECT MIN(id) FROM dbo.users WHERE role = 'owner')),
                @title,
                'Description for property ' + CAST(@prop_counter AS NVARCHAR(10)),
                CAST(@prop_counter AS NVARCHAR(10)) + ' Sample St',
                @city, @state, '1000' + CAST(@prop_counter AS NVARCHAR(10)), 'USA',
                @ptype_id, @status_id,
                2000.00 + (@prop_counter * 10),
                2000.00 + (@prop_counter * 10),
                DATEADD(DAY, @prop_counter, '2024-01-01'),
                2000.00 + (@prop_counter * 10),
                (@prop_counter % 5),
                CAST((@prop_counter % 3) AS DECIMAL(10,2)),
                CAST(500 + @prop_counter AS DECIMAL(10,2))
            );
        END
        SET @prop_counter = @prop_counter + 1;
    END

    -- ------------------------------------------------------------------
    -- Leases: create leases for properties where not exist (idempotent)
    -- Use lookups for tenant selection to avoid hard-coded IDs
    -- ------------------------------------------------------------------
    DECLARE @lease_counter INT = 3;
    WHILE @lease_counter <= 250
    BEGIN
        DECLARE @propTitle NVARCHAR(200) = 'Property ' + CAST(@lease_counter AS NVARCHAR(10));
        DECLARE @propId INT = (SELECT id FROM dbo.properties WHERE title = @propTitle);

        -- select a tenant id in a distributed way among renter users
        DECLARE @tenantCount INT = (SELECT COUNT(*) FROM dbo.users WHERE role = 'renter');
        DECLARE @tenantId INT = NULL;
        IF @tenantCount > 0
        BEGIN
            DECLARE @offset INT = ((@lease_counter - 3) % @tenantCount);
            SELECT @tenantId = id FROM (
                SELECT id, ROW_NUMBER() OVER (ORDER BY id) AS rn FROM dbo.users WHERE role = 'renter'
            ) AS r WHERE rn = @offset + 1;
        END

        IF @propId IS NOT NULL AND @tenantId IS NOT NULL
        BEGIN
            DECLARE @startDate DATE = DATEADD(MONTH, @lease_counter % 12, '2024-01-01');
            DECLARE @endDate DATE = DATEADD(MONTH, @lease_counter % 12 + 12, '2024-01-01');
            IF NOT EXISTS (SELECT 1 FROM dbo.leases WHERE property_id = @propId AND tenant_id = @tenantId AND start_date = @startDate)
            BEGIN
                INSERT INTO dbo.leases (property_id, tenant_id, start_date, end_date, monthly_rent, security_deposit, is_active, created_at)
                VALUES (
                    @propId,
                    @tenantId,
                    @startDate,
                    @endDate,
                    2000.00 + (@lease_counter * 10),
                    2000.00 + (@lease_counter * 10),
                    CASE WHEN @lease_counter % 5 = 0 THEN 0 ELSE 1 END,
                    GETDATE()
                );
            END
        END

        SET @lease_counter = @lease_counter + 1;
    END

    -- ------------------------------------------------------------------
    -- utilities_base: create many utility types (idempotent)
    -- ------------------------------------------------------------------
    DECLARE @util_base_counter INT = 1;
    WHILE @util_base_counter <= 250
    BEGIN
        DECLARE @utilName NVARCHAR(200) = 'Utility ' + CAST(@util_base_counter AS NVARCHAR(10));
        IF NOT EXISTS (SELECT 1 FROM dbo.utilities_base WHERE name = @utilName)
        BEGIN
            INSERT INTO dbo.utilities_base (name, description, rate_per_unit, unit_name, created_at)
            VALUES (
                @utilName,
                'Description for utility ' + CAST(@util_base_counter AS NVARCHAR(10)),
                0.50 + (@util_base_counter * 0.01),
                CASE WHEN @util_base_counter % 4 = 0 THEN 'kWh' WHEN @util_base_counter % 4 = 1 THEN 'gallons' WHEN @util_base_counter % 4 = 2 THEN 'cubic meters' ELSE 'units' END,
                GETDATE()
            );
        END
        SET @util_base_counter = @util_base_counter + 1;
    END

    -- ------------------------------------------------------------------
    -- utilities: create utility reading rows where lease & base exist (idempotent by lease_id+utility_base_id+reading_date)
    -- ------------------------------------------------------------------
    DECLARE @util_counter INT = 1;
    WHILE @util_counter <= 250
    BEGIN
        IF EXISTS (SELECT 1 FROM dbo.leases WHERE id = @util_counter) AND EXISTS (SELECT 1 FROM dbo.utilities_base WHERE id = @util_counter)
        BEGIN
            DECLARE @readingDate DATETIME = DATEADD(DAY, -@util_counter, GETDATE());
            IF NOT EXISTS (SELECT 1 FROM dbo.utilities WHERE lease_id = @util_counter AND utility_base_id = @util_counter AND CAST(reading_date AS DATE) = CAST(@readingDate AS DATE))
            BEGIN
                INSERT INTO dbo.utilities (lease_id, utility_base_id, reading_date, reading_value, rate_at_reading, total_amount, payment_status, created_at)
                VALUES (
                    @util_counter,
                    @util_counter,
                    @readingDate,
                    100.00 + (@util_counter * 10),
                    0.50 + (@util_counter * 0.01),
                    (100.00 + (@util_counter * 10)) * (0.50 + (@util_counter * 0.01)),
                    CASE WHEN @util_counter % 3 = 0 THEN 'Pending' ELSE 'Completed' END,
                    GETDATE()
                );
            END
        END
        SET @util_counter = @util_counter + 1;
    END

    -- ------------------------------------------------------------------
    -- payments: create payments guarded by unique reference_number
    -- ------------------------------------------------------------------
    DECLARE @p_counter INT = 10;
    WHILE @p_counter <= 200
    BEGIN
        DECLARE @ref NVARCHAR(50) = 'REF' + CAST(@p_counter AS NVARCHAR(10));
        IF NOT EXISTS (SELECT 1 FROM dbo.payments WHERE reference_number = @ref)
        BEGIN
            INSERT INTO dbo.payments (lease_id, payment_type, payment_method, amount, payment_date, payment_status, reference_number, created_at)
            VALUES (
                CASE WHEN @p_counter % 2 = 0 THEN 1 ELSE 2 END,
                CASE WHEN @p_counter % 3 = 0 THEN 'Utility' ELSE 'Rent' END,
                CASE WHEN @p_counter % 4 = 0 THEN 'Cash' WHEN @p_counter % 4 = 1 THEN 'Bank Transfer' WHEN @p_counter % 4 = 2 THEN 'Card' ELSE 'Bank Transfer' END,
                CASE WHEN @p_counter % 2 = 0 THEN 2500.00 ELSE 3200.00 END,
                DATEADD(DAY, - (@p_counter * 7), GETDATE()),
                CASE WHEN @p_counter % 10 = 0 THEN 'Pending' ELSE 'Completed' END,
                @ref,
                GETDATE()
            );
        END
        SET @p_counter = @p_counter + 1;
    END

    -- ------------------------------------------------------------------
    -- Sample specific property and full property row inserts (idempotent)
    -- Use FK id lookups for types and statuses
    -- ------------------------------------------------------------------
    -- Simple sample property
    IF NOT EXISTS (SELECT 1 FROM dbo.properties WHERE title = 'Modern Downtown Apartment')
    BEGIN
        INSERT INTO dbo.properties (owner_id, title, description, address, city, state, zip_code, country, property_type_id, status_id, monthly_rent, security_deposit, available_from, rent_amount, bedrooms, bathrooms, area)
        VALUES (
            (SELECT id FROM dbo.users WHERE email = 'owner@example.com'),
            'Modern Downtown Apartment',
            'A beautiful modern apartment in the heart of downtown',
            '123 Main St', 'New York', 'NY', '10001', 'USA',
            (SELECT id FROM dbo.property_types WHERE type_name = 'Apartment'),
            (SELECT id FROM dbo.property_statuses WHERE status_name = 'Available'),
            2500.00, 2500.00, '2024-01-01', 2500.00, 0, 0.00, 0.00
        );
    END

    -- Full detailed sample property
    IF NOT EXISTS (SELECT 1 FROM dbo.properties WHERE title = 'Modern Downtown Apartment - Full')
    BEGIN
        INSERT INTO dbo.properties (
            owner_id, title, property_code, description, address, street, city, state, zip_code, country,
            property_type_id, status_id, bedrooms, bathrooms, area, floor_number, total_floors, furnishing_type,
            parking_space, balcony, facing_direction, age_of_property, monthly_rent, rent_amount,
            security_deposit, deposit_amount, electricity_rate, internet_rate, water_bill, maintenance_charges,
            gas_charges, elevator, gym_pool_clubhouse, security_features, garden_park_access, internet_provider,
            owner_name, owner_contact, listing_date, lease_terms_default, available_from, created_at, updated_at
        )
        VALUES (
            (SELECT id FROM dbo.users WHERE email = 'owner@example.com'),
            'Modern Downtown Apartment - Full', 'MD-APT-001', 'Fully populated test property', '123 Main St', 'Main St', 'New York', 'NY', '10001', 'USA',
            (SELECT id FROM dbo.property_types WHERE type_name = 'Apartment'),
            (SELECT id FROM dbo.property_statuses WHERE status_name = 'Available'),
            2, 1.50, 850.50, 3, 10, 'Furnished', 'Covered', 'Yes', 'North', 5,
            3500.00, 3500.00, 3500.00, 500.00, 0.15, 40.00, 30.00, 150.00, 20.00,
            1, 1, 'Gated community; CCTV', 1, 'ProviderX', 'Olivia Owner', '555-1234', '2024-01-01', 'Standard lease terms', '2024-02-01', GETDATE(), NULL
        );
    END

    -- ------------------------------------------------------------------
    -- Full-coverage lease and payment linked to the above full property
    -- ------------------------------------------------------------------
    DECLARE @fullPropId INT = (SELECT TOP 1 id FROM dbo.properties WHERE title = 'Modern Downtown Apartment - Full');
    DECLARE @renterId INT = (SELECT id FROM dbo.users WHERE email = 'renter@example.com');

    IF @fullPropId IS NOT NULL AND @renterId IS NOT NULL
    BEGIN
        IF NOT EXISTS (SELECT 1 FROM dbo.leases l WHERE l.property_id = @fullPropId AND l.tenant_id = @renterId)
        BEGIN
            INSERT INTO dbo.leases (property_id, tenant_id, start_date, end_date, monthly_rent, security_deposit, is_active, created_at)
            VALUES (@fullPropId, @renterId, '2024-03-01', '2025-02-28', 3500.00, 3500.00, 1, GETDATE());
        END

        DECLARE @payLeaseId INT = (SELECT TOP 1 id FROM dbo.leases WHERE property_id = @fullPropId AND tenant_id = @renterId);
        IF @payLeaseId IS NOT NULL
        BEGIN
            IF NOT EXISTS (SELECT 1 FROM dbo.payments p WHERE p.lease_id = @payLeaseId AND p.reference_number = 'FULL-REF-001')
            BEGIN
                INSERT INTO dbo.payments (lease_id, property_id, tenant_id, payment_type, payment_method, amount, payment_date, payment_status, reference_number, created_at)
                VALUES (
                    @payLeaseId,
                    (SELECT property_id FROM dbo.leases WHERE id = @payLeaseId),
                    (SELECT tenant_id FROM dbo.leases WHERE id = @payLeaseId),
                    (SELECT type_name FROM dbo.payment_types WHERE type_name = 'Rent'),
                    (SELECT method_name FROM dbo.payment_methods WHERE method_name = 'Bank Transfer'),
                    3500.00, GETDATE(), (SELECT status_name FROM dbo.payment_statuses WHERE status_name = 'Completed'), 'FULL-REF-001', GETDATE()
                );
            END
        END
    END

    -- ------------------------------------------------------------------
    -- Utilities: add a single electricity reading for the earliest lease if not exists
    -- ------------------------------------------------------------------
    DECLARE @leaseForUtilities INT = (SELECT TOP 1 id FROM dbo.leases ORDER BY id ASC);
    IF @leaseForUtilities IS NOT NULL AND EXISTS (SELECT 1 FROM dbo.utilities_base WHERE name = 'Electricity')
    BEGIN
        IF NOT EXISTS (SELECT 1 FROM dbo.utilities u WHERE u.lease_id = @leaseForUtilities AND u.utility_base_id = (SELECT id FROM dbo.utilities_base WHERE name = 'Electricity'))
        BEGIN
            INSERT INTO dbo.utilities (lease_id, property_id, utility_base_id, utility_type, reading_date, reading_value, rate_at_reading, total_amount, amount, payment_status, status, created_at)
            VALUES (
                @leaseForUtilities,
                (SELECT property_id FROM dbo.leases WHERE id = @leaseForUtilities),
                (SELECT id FROM dbo.utilities_base WHERE name = 'Electricity'),
                'Electricity', GETDATE(), 120.50, 0.12, 120.50*0.12, 14.46, 'Pending', 'Recorded', GETDATE()
            );
        END
    END

    COMMIT TRANSACTION;
    PRINT 'Seed completed: idempotent data inserted/checked.';
END TRY
BEGIN CATCH
    IF XACT_STATE() <> 0
    BEGIN
        ROLLBACK TRANSACTION;
    END
    DECLARE @ErrMsg NVARCHAR(4000) = ERROR_MESSAGE();
    DECLARE @ErrNum INT = ERROR_NUMBER();
    PRINT 'ERROR: ' + ISNULL(CAST(@ErrNum AS NVARCHAR(20)), '') + ' - ' + ISNULL(@ErrMsg,'(no message)');
    THROW;
END CATCH;
GO
