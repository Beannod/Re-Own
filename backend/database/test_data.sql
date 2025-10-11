-- Test Data Generation Script

-- Clear existing data
DELETE FROM payments;
DELETE FROM utilities;
DELETE FROM lease_invitations;
DELETE FROM leases;
DELETE FROM property_documents;
DELETE FROM properties;
DELETE FROM renter_profiles;
DELETE FROM owner_profiles;
DELETE FROM users;
GO

-- Create owners
DECLARE @Counter INT = 1;
WHILE @Counter <= 25
BEGIN
    -- Create owner
    DECLARE @OwnerEmail NVARCHAR(255) = CONCAT('owner', @Counter, '@example.com');
    DECLARE @OwnerUsername NVARCHAR(50) = CONCAT('owner', @Counter);
    DECLARE @OwnerFullName NVARCHAR(100) = CONCAT('Test Owner ', @Counter);
    
    EXEC sp_CreateUser 
        @Email = @OwnerEmail,
        @Username = @OwnerUsername,
        @HashedPassword = '$pbkdf2-sha256$29000$be0dA.DcG6N0zvnfe29tTQ$eNSBYAUG4T9vFAMWSN8TXu7NxqODgD7im9sSlESQyGM',  -- password: test123
        @FullName = @OwnerFullName,
        @Role = 'owner';

    -- Create owner profile
    DECLARE @OwnerId INT;
    SELECT @OwnerId = id FROM users WHERE email = @OwnerEmail;
    
    DECLARE @OwnerPhone NVARCHAR(20) = CONCAT('555-000-', RIGHT('0000' + CAST(@Counter AS VARCHAR(4)), 4));
    DECLARE @Company NVARCHAR(200) = CONCAT('Property Management ', @Counter);
    
    EXEC sp_CreateOwnerProfile
        @UserId = @OwnerId,
        @Phone = @OwnerPhone,
        @Company = @Company;

    SET @Counter = @Counter + 1;
END;
GO

-- Create renters
DECLARE @Counter INT = 1;
WHILE @Counter <= 25
BEGIN
    -- Create renter
    DECLARE @RenterEmail NVARCHAR(255) = CONCAT('renter', @Counter, '@example.com');
    DECLARE @RenterUsername NVARCHAR(50) = CONCAT('renter', @Counter);
    DECLARE @RenterFullName NVARCHAR(100) = CONCAT('Test Renter ', @Counter);
    
    EXEC sp_CreateUser 
        @Email = @RenterEmail,
        @Username = @RenterUsername,
        @HashedPassword = '$pbkdf2-sha256$29000$be0dA.DcG6N0zvnfe29tTQ$eNSBYAUG4T9vFAMWSN8TXu7NxqODgD7im9sSlESQyGM',  -- password: test123
        @FullName = @RenterFullName,
        @Role = 'renter';

    -- Create renter profile
    DECLARE @RenterId INT;
    SELECT @RenterId = id FROM users WHERE email = @RenterEmail;
    
    DECLARE @RenterPhone NVARCHAR(20) = CONCAT('555-111-', RIGHT('0000' + CAST(@Counter AS VARCHAR(4)), 4));
    DECLARE @RenterAddress NVARCHAR(500) = CONCAT('Renter St #', @Counter);
    EXEC sp_CreateRenterProfile
        @UserId = @RenterId,
        @Phone = @RenterPhone,
        @Address = @RenterAddress;

    SET @Counter = @Counter + 1;
END;
GO

-- Generate 50 properties
DECLARE @Counter INT = 1;
WHILE @Counter <= 50
BEGIN
    DECLARE @OwnerId INT;
    SELECT @OwnerId = id FROM users WHERE email = CONCAT('owner', ((@Counter - 1) % 25 + 1), '@example.com');

    DECLARE @PropertyType VARCHAR(20) = CASE 
        WHEN @Counter % 4 = 0 THEN 'apartment'
        WHEN @Counter % 4 = 1 THEN 'house'
        WHEN @Counter % 4 = 2 THEN 'condo'
        ELSE 'duplex'
    END;

    -- Deterministic distribution to guarantee >20 rows for leases & invitations
    DECLARE @Status VARCHAR(20) = CASE 
        WHEN @Counter <= 25 THEN 'rented'          -- ensures at least 25 leases possible
        WHEN @Counter <= 47 THEN 'available'       -- ensures at least 22 invitations
        ELSE 'maintenance'
    END;

    INSERT INTO properties (
        owner_id, title, address, property_type, 
        bedrooms, bathrooms, area, rent_amount,
        deposit_amount, description, status
    )
    VALUES (
        @OwnerId,
        CONCAT('Property ', @Counter),
        CONCAT(@Counter, ' Main Street, ', 
            CASE 
                WHEN @Counter % 5 = 0 THEN 'New York, NY'
                WHEN @Counter % 5 = 1 THEN 'Los Angeles, CA'
                WHEN @Counter % 5 = 2 THEN 'Chicago, IL'
                WHEN @Counter % 5 = 3 THEN 'Houston, TX'
                ELSE 'Phoenix, AZ'
            END,
            ' ', CONCAT('1', RIGHT('0000' + CAST(@Counter AS VARCHAR(4)), 4))
        ),
        @PropertyType,
        (@Counter % 3) + 1,
        (@Counter % 2) + 1,
        800 + (@Counter * 100),
        1000 + (@Counter * 50),
        2000 + (@Counter * 100),
        CONCAT('A beautiful ', @PropertyType, ' in a great location. Property ID: ', @Counter),
        @Status
    );

    -- Create property documents: both even and some odd to exceed 20
    IF @Counter % 2 = 0 OR @Counter % 5 = 1
    BEGIN
        INSERT INTO property_documents (
            property_id,
            file_name,
            file_path,
            content_type
        )
        VALUES (
            @Counter,
            CONCAT('property_', @Counter, '_doc.pdf'),
            CONCAT('/uploads/property_docs/property_', @Counter, '_doc.pdf'),
            'application/pdf'
        );
    END;

    SET @Counter = @Counter + 1;
END;
GO

-- Generate leases and invitations
DECLARE @Counter INT = 1;
WHILE @Counter <= 50
BEGIN
    -- Only create leases for properties marked as 'rented'
    IF EXISTS (SELECT 1 FROM properties WHERE id = @Counter AND status = 'rented')
    BEGIN
        DECLARE @RenterId INT;
        SELECT TOP 1 @RenterId = id 
        FROM users 
        WHERE role = 'renter' 
        AND NOT EXISTS (
            SELECT 1 FROM leases 
            WHERE tenant_id = users.id 
            AND status = 'active'
        )
        ORDER BY NEWID();

        IF @RenterId IS NOT NULL
        BEGIN
            -- Create an approved lease invitation
            INSERT INTO lease_invitations (
                owner_id,
                renter_id,
                property_id,
                start_date,
                rent_amount,
                deposit_amount,
                status,
                created_at
            )
            SELECT 
                p.owner_id,
                @RenterId,
                p.id,
                DATEADD(DAY, -30, GETDATE()),
                p.rent_amount,
                p.deposit_amount,
                'approved',
                DATEADD(DAY, -35, GETDATE())
            FROM properties p
            WHERE p.id = @Counter;

            -- Create the actual lease
            INSERT INTO leases (
                tenant_id,
                property_id,
                start_date,
                end_date,
                rent_amount,
                deposit_amount,
                status,
                created_at
            )
            SELECT
                @RenterId,
                id,
                DATEADD(DAY, -30, GETDATE()),
                DATEADD(YEAR, 1, DATEADD(DAY, -30, GETDATE())),
                rent_amount,
                deposit_amount,
                'active',
                DATEADD(DAY, -30, GETDATE())
            FROM properties
            WHERE id = @Counter;

            -- Generate some payments for this lease
            DECLARE @LeaseId INT = SCOPE_IDENTITY();
            DECLARE @PaymentCounter INT = 1;
            WHILE @PaymentCounter <= 4
            BEGIN
                INSERT INTO payments (
                    property_id,
                    tenant_id,
                    amount,
                    payment_type,
                    payment_method,
                    payment_status,
                    payment_date
                )
                VALUES (
                    @Counter,
                    @RenterId,
                    (SELECT rent_amount FROM properties WHERE id = @Counter),
                    CASE WHEN @PaymentCounter=4 THEN 'deposit' ELSE 'rent' END,
                    CASE WHEN @PaymentCounter % 3 = 0 THEN 'cash'
                         WHEN @PaymentCounter % 3 = 1 THEN 'card'
                         ELSE 'bank_transfer' END,
                    CASE WHEN @PaymentCounter=1 THEN 'pending' ELSE 'completed' END,
                    DATEADD(MONTH, -@PaymentCounter, GETDATE())
                );

                SET @PaymentCounter = @PaymentCounter + 1;
            END;
        END;
    END;

    -- Create pending lease invitations for available properties
    IF EXISTS (SELECT 1 FROM properties WHERE id = @Counter AND status = 'available')
    BEGIN
        DECLARE @PendingRenterId INT;
        SELECT TOP 1 @PendingRenterId = id 
        FROM users 
        WHERE role = 'renter' 
        AND NOT EXISTS (
            SELECT 1 FROM lease_invitations 
            WHERE renter_id = users.id 
            AND status = 'pending'
        )
        ORDER BY NEWID();

        IF @PendingRenterId IS NOT NULL
        BEGIN
            INSERT INTO lease_invitations (
                owner_id,
                renter_id,
                property_id,
                start_date,
                rent_amount,
                deposit_amount,
                status,
                created_at
            )
            SELECT 
                p.owner_id,
                @PendingRenterId,
                p.id,
                DATEADD(DAY, 5, GETDATE()),
                p.rent_amount,
                p.deposit_amount,
                'pending',
                GETDATE()
            FROM properties p
            WHERE p.id = @Counter;
        END;
    END;

    SET @Counter = @Counter + 1;
END;
GO

-- Generate utilities for all properties
INSERT INTO utilities (
    property_id,
    utility_type,
    reading_date,
    reading_value,
    amount,
    status
)
SELECT 
    id,
    'electricity',
    DATEADD(DAY, -15, GETDATE()),
    100 + (id * 5),
    50 + (id * 2),
    CASE WHEN id % 4 = 0 THEN 'paid' ELSE 'pending' END
FROM properties;

INSERT INTO utilities (
    property_id,
    utility_type,
    reading_date,
    reading_value,
    amount,
    status
)
SELECT 
    id,
    'water',
    DATEADD(DAY, -15, GETDATE()),
    30 + (id * 2),
    25 + id,
    CASE WHEN id % 5 = 0 THEN 'paid' ELSE 'pending' END
FROM properties;

-- Add gas utility to further increase volume & coverage
INSERT INTO utilities (
    property_id,
    utility_type,
    reading_date,
    reading_value,
    amount,
    status
)
SELECT 
    id,
    'gas',
    DATEADD(DAY, -10, GETDATE()),
    20 + id,
    15 + (id % 10),
    CASE WHEN id % 6 = 0 THEN 'paid' ELSE 'pending' END
FROM properties;

-- Add maintenance records
INSERT INTO utilities (
    property_id,
    utility_type,
    reading_date,
    reading_value,
    amount,
    status
)
SELECT 
    id,
    'maintenance',
    GETDATE(),
    0,  -- Maintenance doesn't really have a reading value
    500,
    'pending'
FROM properties 
WHERE status = 'maintenance';
GO

-- Additional payments for available properties as application/deposits to exceed 20 total
INSERT INTO payments (
    property_id,
    tenant_id,
    amount,
    payment_type,
    payment_method,
    payment_status,
    payment_date
)
SELECT TOP (30)
    p.id,
    (SELECT TOP 1 id FROM users WHERE role = 'renter' ORDER BY NEWID()),
    p.deposit_amount,
    'deposit',
    'card',
    'completed',
    DATEADD(DAY, -7, GETDATE())
FROM properties p
WHERE p.status = 'available';
GO