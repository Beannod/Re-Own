-- Complete Database Setup Script for Re-Own
-- Optimized and cleaned version

-- Start with fresh schema by dropping tables in correct order
DROP TABLE IF EXISTS payments;
DROP TABLE IF EXISTS utilities;
DROP TABLE IF EXISTS lease_invitations;
DROP TABLE IF EXISTS leases;
DROP TABLE IF EXISTS property_documents;
DROP TABLE IF EXISTS properties;
DROP TABLE IF EXISTS renter_profiles;
DROP TABLE IF EXISTS owner_profiles;
DROP TABLE IF EXISTS users;
GO

-- Create Users table if it doesn't exist
IF OBJECT_ID('users', 'U') IS NULL
CREATE TABLE users (
    id INT IDENTITY(1,1) PRIMARY KEY,
    email NVARCHAR(255) UNIQUE NOT NULL,
    username NVARCHAR(50) UNIQUE NOT NULL,
    hashed_password NVARCHAR(255) NOT NULL,
    full_name NVARCHAR(100) NOT NULL,
    role NVARCHAR(20) NOT NULL,
    is_active BIT NOT NULL DEFAULT 1,
    created_at DATETIME2 NOT NULL DEFAULT GETDATE(),
    updated_at DATETIME2 NULL
);
GO

-- Create Profile tables
IF OBJECT_ID('owner_profiles', 'U') IS NULL
CREATE TABLE owner_profiles (
    id INT IDENTITY(1,1) PRIMARY KEY,
    user_id INT NOT NULL UNIQUE,
    phone NVARCHAR(30) NULL,
    address NVARCHAR(500) NULL,
    company NVARCHAR(200) NULL,
    created_at DATETIME2 NOT NULL DEFAULT GETDATE(),
    updated_at DATETIME2 NULL,
    FOREIGN KEY (user_id) REFERENCES users(id)
);
GO

IF OBJECT_ID('renter_profiles', 'U') IS NULL
CREATE TABLE renter_profiles (
    id INT IDENTITY(1,1) PRIMARY KEY,
    user_id INT NOT NULL UNIQUE,
    phone NVARCHAR(30) NULL,
    address NVARCHAR(500) NULL,
    lease_start DATE NULL,
    lease_end DATE NULL,
    created_at DATETIME2 NOT NULL DEFAULT GETDATE(),
    updated_at DATETIME2 NULL,
    FOREIGN KEY (user_id) REFERENCES users(id)
);
GO

-- Create Properties table
IF OBJECT_ID('properties', 'U') IS NULL
CREATE TABLE properties (
    id INT IDENTITY(1,1) PRIMARY KEY,
    owner_id INT NOT NULL,
    title NVARCHAR(200) NOT NULL,
    address NVARCHAR(500) NOT NULL,
    property_type NVARCHAR(50) NOT NULL,
    bedrooms INT NULL,
    bathrooms INT NULL,
    area FLOAT NULL,
    rent_amount FLOAT NOT NULL,
    deposit_amount FLOAT NULL,
    description NTEXT NULL,
    status NVARCHAR(50) NOT NULL DEFAULT 'available',
    created_at DATETIME2 NOT NULL DEFAULT GETDATE(),
    updated_at DATETIME2 NULL,
    FOREIGN KEY (owner_id) REFERENCES users(id)
);
GO

-- Create Property Documents table
IF OBJECT_ID('property_documents', 'U') IS NULL
CREATE TABLE property_documents (
    id INT IDENTITY(1,1) PRIMARY KEY,
    property_id INT NOT NULL,
    file_name NVARCHAR(255) NOT NULL,
    file_path NVARCHAR(1000) NOT NULL,
    content_type NVARCHAR(100) NULL,
    uploaded_at DATETIME2 NOT NULL DEFAULT GETDATE(),
    FOREIGN KEY (property_id) REFERENCES properties(id)
);
GO

-- Create Leases table
IF OBJECT_ID('leases', 'U') IS NULL
CREATE TABLE leases (
    id INT IDENTITY(1,1) PRIMARY KEY,
    tenant_id INT NOT NULL,
    property_id INT NOT NULL,
    start_date DATE NOT NULL,
    end_date DATE NULL,
    rent_amount FLOAT NOT NULL,
    deposit_amount FLOAT NULL,
    status NVARCHAR(20) NOT NULL DEFAULT 'active',
    created_at DATETIME2 NOT NULL DEFAULT GETDATE(),
    updated_at DATETIME2 NULL,
    FOREIGN KEY (tenant_id) REFERENCES users(id),
    FOREIGN KEY (property_id) REFERENCES properties(id)
);
GO

-- Create Payments table
IF OBJECT_ID('payments', 'U') IS NULL
CREATE TABLE payments (
    id INT IDENTITY(1,1) PRIMARY KEY,
    property_id INT NOT NULL,
    tenant_id INT NOT NULL,
    amount FLOAT NOT NULL,
    payment_type NVARCHAR(50) NOT NULL,
    payment_method NVARCHAR(50) NOT NULL,
    payment_status NVARCHAR(50) NOT NULL,
    payment_date DATETIME2 NOT NULL,
    created_at DATETIME2 NOT NULL DEFAULT GETDATE(),
    updated_at DATETIME2 NULL,
    FOREIGN KEY (property_id) REFERENCES properties(id),
    FOREIGN KEY (tenant_id) REFERENCES users(id)
);
GO

-- Create Utilities table
IF OBJECT_ID('utilities', 'U') IS NULL
CREATE TABLE utilities (
    id INT IDENTITY(1,1) PRIMARY KEY,
    property_id INT NOT NULL,
    utility_type NVARCHAR(50) NOT NULL,
    reading_date DATETIME2 NOT NULL,
    reading_value FLOAT NOT NULL,
    amount FLOAT NOT NULL,
    status NVARCHAR(50) NOT NULL,
    created_at DATETIME2 NOT NULL DEFAULT GETDATE(),
    updated_at DATETIME2 NULL,
    FOREIGN KEY (property_id) REFERENCES properties(id)
);
GO

-- Create Lease Invitations table (for approval workflow)
IF OBJECT_ID('lease_invitations', 'U') IS NULL
CREATE TABLE lease_invitations (
    id INT IDENTITY(1,1) PRIMARY KEY,
    owner_id INT NOT NULL,
    renter_id INT NOT NULL,
    property_id INT NOT NULL,
    start_date DATE NOT NULL,
    rent_amount FLOAT NOT NULL,
    deposit_amount FLOAT NULL,
    status NVARCHAR(20) NOT NULL DEFAULT 'pending', -- pending | approved | rejected | canceled
    created_at DATETIME2 NOT NULL DEFAULT GETDATE(),
    updated_at DATETIME2 NULL,
    FOREIGN KEY (owner_id) REFERENCES users(id),
    FOREIGN KEY (renter_id) REFERENCES users(id),
    FOREIGN KEY (property_id) REFERENCES properties(id)
);
GO

-- Drop existing stored procedures
IF OBJECT_ID('sp_GetUserByEmail', 'P') IS NOT NULL DROP PROCEDURE sp_GetUserByEmail;
IF OBJECT_ID('sp_GetUserById', 'P') IS NOT NULL DROP PROCEDURE sp_GetUserById;
IF OBJECT_ID('sp_CreateUser', 'P') IS NOT NULL DROP PROCEDURE sp_CreateUser;
IF OBJECT_ID('sp_UpdateUser', 'P') IS NOT NULL DROP PROCEDURE sp_UpdateUser;
IF OBJECT_ID('sp_DeleteUser', 'P') IS NOT NULL DROP PROCEDURE sp_DeleteUser;
IF OBJECT_ID('sp_CreateOwnerProfile', 'P') IS NOT NULL DROP PROCEDURE sp_CreateOwnerProfile;
IF OBJECT_ID('sp_UpdateOwnerProfile', 'P') IS NOT NULL DROP PROCEDURE sp_UpdateOwnerProfile;
IF OBJECT_ID('sp_GetOwnerProfile', 'P') IS NOT NULL DROP PROCEDURE sp_GetOwnerProfile;
IF OBJECT_ID('sp_CreateRenterProfile', 'P') IS NOT NULL DROP PROCEDURE sp_CreateRenterProfile;
IF OBJECT_ID('sp_UpdateRenterProfile', 'P') IS NOT NULL DROP PROCEDURE sp_UpdateRenterProfile;
IF OBJECT_ID('sp_GetRenterProfile', 'P') IS NOT NULL DROP PROCEDURE sp_GetRenterProfile;
IF OBJECT_ID('sp_CreateProperty', 'P') IS NOT NULL DROP PROCEDURE sp_CreateProperty;
IF OBJECT_ID('sp_UpdateProperty', 'P') IS NOT NULL DROP PROCEDURE sp_UpdateProperty;
IF OBJECT_ID('sp_DeleteProperty', 'P') IS NOT NULL DROP PROCEDURE sp_DeleteProperty;
IF OBJECT_ID('sp_GetProperty', 'P') IS NOT NULL DROP PROCEDURE sp_GetProperty;
IF OBJECT_ID('sp_GetAllProperties', 'P') IS NOT NULL DROP PROCEDURE sp_GetAllProperties;
IF OBJECT_ID('sp_CreateLease', 'P') IS NOT NULL DROP PROCEDURE sp_CreateLease;
IF OBJECT_ID('sp_GetLease', 'P') IS NOT NULL DROP PROCEDURE sp_GetLease;
IF OBJECT_ID('sp_UpdateLease', 'P') IS NOT NULL DROP PROCEDURE sp_UpdateLease;
IF OBJECT_ID('sp_ListLeases', 'P') IS NOT NULL DROP PROCEDURE sp_ListLeases;
IF OBJECT_ID('sp_GetActiveLeaseByProperty', 'P') IS NOT NULL DROP PROCEDURE sp_GetActiveLeaseByProperty;
IF OBJECT_ID('sp_GetLeasesByProperty', 'P') IS NOT NULL DROP PROCEDURE sp_GetLeasesByProperty;
GO

-- Create User Management Stored Procedures
CREATE PROCEDURE sp_GetUserByEmail
    @Email NVARCHAR(255)
AS
BEGIN
    SET NOCOUNT ON;
    SELECT id, email, username, hashed_password, full_name, role, is_active
    FROM users
    WHERE email = @Email AND is_active = 1;
END;
GO

-- ===================== Consolidated: Additional Procedures =====================

-- Users listing with filters
CREATE OR ALTER PROCEDURE sp_GetAllUsers
    @Role NVARCHAR(20) = NULL,
    @IsActive BIT = NULL,
    @SearchTerm NVARCHAR(255) = NULL
AS
BEGIN
    SET NOCOUNT ON;

    IF @Role IS NOT NULL AND @Role NOT IN ('owner', 'renter', 'admin')
    BEGIN
        RAISERROR ('Invalid role filter. Role must be either "owner", "renter", or "admin".', 16, 1);
        RETURN;
    END

    DECLARE @SQL NVARCHAR(MAX) = N'
        SELECT 
            u.id, 
            u.email, 
            u.username, 
            u.full_name, 
            u.role, 
            u.is_active, 
            u.created_at, 
            u.updated_at
        FROM users u
        WHERE 1=1';

    IF @Role IS NOT NULL
        SET @SQL = @SQL + N' AND role = @Role';

    IF @IsActive IS NOT NULL
        SET @SQL = @SQL + N' AND is_active = @IsActive';

    IF @SearchTerm IS NOT NULL
        SET @SQL = @SQL + N' AND (
            email LIKE ''%'' + @SearchTerm + ''%'' OR
            username LIKE ''%'' + @SearchTerm + ''%'' OR
            full_name LIKE ''%'' + @SearchTerm + ''%''
        )';

    SET @SQL = @SQL + N' ORDER BY created_at DESC';

    DECLARE @Params NVARCHAR(MAX) = N'@Role NVARCHAR(20), @IsActive BIT, @SearchTerm NVARCHAR(255)';
    EXEC sp_executesql @SQL, @Params, @Role=@Role, @IsActive=@IsActive, @SearchTerm=@SearchTerm;
END;
GO

-- Utilities list
CREATE OR ALTER PROCEDURE sp_ListUtilities
    @PropertyId INT = NULL,
    @TenantId INT = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SELECT 
        u.id,
        u.property_id,
        u.utility_type,
        u.reading_date,
        u.reading_value,
        u.amount,
        u.status,
        u.created_at,
        u.updated_at,
        p.title as property_title
    FROM utilities u
    LEFT JOIN properties p ON u.property_id = p.id
    LEFT JOIN leases l ON l.property_id = u.property_id AND l.status = 'active' AND (l.end_date IS NULL OR l.end_date > GETDATE())
    WHERE (@PropertyId IS NULL OR u.property_id = @PropertyId)
      AND (@TenantId IS NULL OR l.tenant_id = @TenantId)
    ORDER BY u.property_id, u.utility_type, u.reading_date DESC;
END;
GO

-- Utility by id
CREATE OR ALTER PROCEDURE sp_GetUtility
    @UtilityId INT
AS
BEGIN
    SET NOCOUNT ON;
    SELECT 
        u.id,
        u.property_id,
        u.utility_type,
        u.reading_date,
        u.reading_value,
        u.amount,
        u.status,
        u.created_at,
        u.updated_at,
        p.title as property_title
    FROM utilities u
    LEFT JOIN properties p ON u.property_id = p.id
    WHERE u.id = @UtilityId;
END;
GO

-- Payments Stored Procedures
IF OBJECT_ID('sp_CreatePayment', 'P') IS NOT NULL DROP PROCEDURE sp_CreatePayment;
GO
IF OBJECT_ID('sp_GetPayment', 'P') IS NOT NULL DROP PROCEDURE sp_GetPayment;
GO
IF OBJECT_ID('sp_ListPayments', 'P') IS NOT NULL DROP PROCEDURE sp_ListPayments;
GO
IF OBJECT_ID('sp_UpdatePaymentStatus', 'P') IS NOT NULL DROP PROCEDURE sp_UpdatePaymentStatus;
GO

CREATE PROCEDURE sp_CreatePayment
    @PropertyId INT,
    @TenantId INT,
    @Amount FLOAT,
    @PaymentType NVARCHAR(50),
    @PaymentMethod NVARCHAR(50),
    @PaymentStatus NVARCHAR(50),
    @PaymentDate DATETIME2
AS
BEGIN
    SET NOCOUNT ON;
    INSERT INTO payments (
        property_id, tenant_id, amount, payment_type, payment_method, payment_status, payment_date, created_at
    )
    OUTPUT INSERTED.id AS PaymentId
    VALUES (
        @PropertyId, @TenantId, @Amount, @PaymentType, @PaymentMethod, @PaymentStatus, @PaymentDate, GETDATE()
    );
END;
GO

CREATE PROCEDURE sp_GetPayment
    @PaymentId INT
AS
BEGIN
    SET NOCOUNT ON;
    SELECT 
        pmt.*,
        pr.title AS property_title,
        usr.full_name AS tenant_name,
        usr.email AS tenant_email
    FROM payments pmt
    LEFT JOIN properties pr ON pr.id = pmt.property_id
    LEFT JOIN users usr ON usr.id = pmt.tenant_id
    WHERE pmt.id = @PaymentId;
END;
GO

CREATE PROCEDURE sp_ListPayments
    @OwnerId INT = NULL,
    @TenantId INT = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SELECT 
        pmt.*,
        pr.title AS property_title,
        usr.full_name AS tenant_name,
        usr.email AS tenant_email
    FROM payments pmt
    LEFT JOIN properties pr ON pr.id = pmt.property_id
    LEFT JOIN users usr ON usr.id = pmt.tenant_id
    WHERE (@TenantId IS NULL OR pmt.tenant_id = @TenantId)
      AND (
            @OwnerId IS NULL 
            OR (@OwnerId IS NOT NULL AND pr.owner_id = @OwnerId)
          )
    ORDER BY pmt.payment_date DESC, pmt.created_at DESC;
END;
GO

CREATE PROCEDURE sp_UpdatePaymentStatus
    @PaymentId INT,
    @PaymentStatus NVARCHAR(50)
AS
BEGIN
    SET NOCOUNT ON;
    UPDATE payments
    SET payment_status = @PaymentStatus,
        updated_at = GETDATE()
    WHERE id = @PaymentId;
    SELECT @@ROWCOUNT AS AffectedRows;
END;
GO

-- Create utility reading (expected by backend)
CREATE OR ALTER PROCEDURE sp_CreateUtilityReading
    @PropertyId INT,
    @UtilityType NVARCHAR(50),
    @ReadingDate DATETIME2,
    @ReadingValue FLOAT,
    @Amount FLOAT,
    @Status NVARCHAR(50)
AS
BEGIN
    SET NOCOUNT ON;

    IF NOT EXISTS (SELECT 1 FROM properties WHERE id = @PropertyId)
    BEGIN
        RAISERROR('Invalid property_id', 16, 1);
        RETURN;
    END

    INSERT INTO utilities (
        property_id, utility_type, reading_date, reading_value, amount, status, created_at
    )
    OUTPUT INSERTED.id AS UtilityId
    VALUES (
        @PropertyId, @UtilityType, @ReadingDate, @ReadingValue, @Amount, @Status, GETDATE()
    );
END;
GO

-- Update utility reading (expected by backend)
CREATE OR ALTER PROCEDURE sp_UpdateUtilityReading
    @UtilityId INT,
    @ReadingValue FLOAT = NULL,
    @Amount FLOAT = NULL,
    @Status NVARCHAR(50) = NULL
AS
BEGIN
    SET NOCOUNT ON;

    IF NOT EXISTS (SELECT 1 FROM utilities WHERE id = @UtilityId)
    BEGIN
        SELECT CAST(0 AS INT) AS AffectedRows;
        RETURN;
    END

    UPDATE utilities
    SET 
        reading_value = COALESCE(@ReadingValue, reading_value),
        amount = COALESCE(@Amount, amount),
        status = COALESCE(@Status, status),
        updated_at = GETDATE()
    WHERE id = @UtilityId;

    SELECT @@ROWCOUNT AS AffectedRows;
END;
GO

CREATE PROCEDURE sp_GetUserById
    @UserId INT
AS
BEGIN
    SET NOCOUNT ON;
    SELECT id, email, username, full_name, role, is_active, created_at, updated_at 
    FROM users 
    WHERE id = @UserId;
END;
GO

CREATE PROCEDURE sp_CreateUser
    @Email NVARCHAR(255),
    @Username NVARCHAR(50),
    @HashedPassword NVARCHAR(255),
    @FullName NVARCHAR(100),
    @Role NVARCHAR(20)
AS
BEGIN
    SET NOCOUNT ON;

    -- Validate email format
    IF @Email NOT LIKE '%_@__%.__%'
    BEGIN
        RAISERROR ('Invalid email format. Please provide a valid email address.', 16, 1);
        RETURN;
    END

    -- Check for duplicate email
    IF EXISTS (SELECT 1 FROM users WHERE email = @Email)
    BEGIN
        RAISERROR ('Email address already registered. Please use a different email.', 16, 1);
        RETURN;
    END

    -- Check for duplicate username
    IF EXISTS (SELECT 1 FROM users WHERE username = @Username)
    BEGIN
        RAISERROR ('Username already taken. Please choose a different username.', 16, 1);
        RETURN;
    END

    -- Validate username format (alphanumeric and underscore only)
    IF @Username LIKE '%[^a-zA-Z0-9_]%'
    BEGIN
        RAISERROR ('Invalid username format. Use only letters, numbers, and underscores.', 16, 1);
        RETURN;
    END

    -- Validate role
    IF @Role NOT IN ('owner', 'renter', 'admin')
    BEGIN
        RAISERROR ('Invalid role. Role must be either "owner", "renter", or "admin".', 16, 1);
        RETURN;
    END

    -- Validate full name is not empty
    IF LEN(TRIM(@FullName)) = 0
    BEGIN
        RAISERROR ('Full name cannot be empty.', 16, 1);
        RETURN;
    END

    -- Validate password is not empty
    IF LEN(@HashedPassword) = 0
    BEGIN
        RAISERROR ('Password cannot be empty.', 16, 1);
        RETURN;
    END

    INSERT INTO users (email, username, hashed_password, full_name, role, created_at)
    VALUES (@Email, @Username, @HashedPassword, @FullName, @Role, GETDATE());
    SELECT SCOPE_IDENTITY() as UserId;
END;
GO

CREATE PROCEDURE sp_UpdateUser
    @UserId INT,
    @Email NVARCHAR(255),
    @Username NVARCHAR(50),
    @FullName NVARCHAR(100),
    @Role NVARCHAR(20)
AS
BEGIN
    SET NOCOUNT ON;
    UPDATE users
    SET email = @Email,
        username = @Username,
        full_name = @FullName,
        role = @Role,
        updated_at = GETDATE()
    WHERE id = @UserId;
    SELECT @@ROWCOUNT as AffectedRows;
END;
GO

CREATE PROCEDURE sp_DeleteUser
    @UserId INT
AS
BEGIN
    SET NOCOUNT ON;
    UPDATE users
    SET is_active = 0,
        updated_at = GETDATE()
    WHERE id = @UserId;
    SELECT @@ROWCOUNT as AffectedRows;
END;
GO

-- Create Profile Management Stored Procedures
CREATE PROCEDURE sp_CreateOwnerProfile
    @UserId INT,
    @Phone NVARCHAR(30) = NULL,
    @Address NVARCHAR(500) = NULL,
    @Company NVARCHAR(200) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    INSERT INTO owner_profiles (user_id, phone, address, company, created_at)
    VALUES (@UserId, @Phone, @Address, @Company, GETDATE());
    SELECT SCOPE_IDENTITY() as OwnerProfileId;
END;
GO

CREATE PROCEDURE sp_UpdateOwnerProfile
    @UserId INT,
    @Phone NVARCHAR(30) = NULL,
    @Address NVARCHAR(500) = NULL,
    @Company NVARCHAR(200) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    UPDATE owner_profiles
    SET phone = @Phone,
        address = @Address,
        company = @Company,
        updated_at = GETDATE()
    WHERE user_id = @UserId;
    SELECT @@ROWCOUNT as AffectedRows;
END;
GO

CREATE PROCEDURE sp_GetOwnerProfile
    @UserId INT
AS
BEGIN
    SET NOCOUNT ON;
    SELECT * FROM owner_profiles WHERE user_id = @UserId;
END;
GO

CREATE PROCEDURE sp_CreateRenterProfile
    @UserId INT,
    @Phone NVARCHAR(30) = NULL,
    @Address NVARCHAR(500) = NULL,
    @LeaseStart DATE = NULL,
    @LeaseEnd DATE = NULL
AS
BEGIN
    SET NOCOUNT ON;
    INSERT INTO renter_profiles (user_id, phone, address, lease_start, lease_end, created_at)
    VALUES (@UserId, @Phone, @Address, @LeaseStart, @LeaseEnd, GETDATE());
    SELECT SCOPE_IDENTITY() as RenterProfileId;
END;
GO

CREATE PROCEDURE sp_UpdateRenterProfile
    @UserId INT,
    @Phone NVARCHAR(30) = NULL,
    @Address NVARCHAR(500) = NULL,
    @LeaseStart DATE = NULL,
    @LeaseEnd DATE = NULL
AS
BEGIN
    SET NOCOUNT ON;
    UPDATE renter_profiles
    SET phone = @Phone,
        address = @Address,
        lease_start = @LeaseStart,
        lease_end = @LeaseEnd,
        updated_at = GETDATE()
    WHERE user_id = @UserId;
    SELECT @@ROWCOUNT as AffectedRows;
END;
GO

CREATE PROCEDURE sp_GetRenterProfile
    @UserId INT
AS
BEGIN
    SET NOCOUNT ON;
    SELECT * FROM renter_profiles WHERE user_id = @UserId;
END;
GO

-- Create Property Management Stored Procedures
CREATE PROCEDURE sp_CreateProperty
    @OwnerId INT,
    @Title NVARCHAR(200),
    @Address NVARCHAR(500),
    @PropertyType NVARCHAR(50),
    @Bedrooms INT,
    @Bathrooms INT,
    @Area FLOAT,
    @RentAmount FLOAT,
    @DepositAmount FLOAT = NULL,
    @Description NTEXT = NULL,
    @Status NVARCHAR(50) = 'available'
AS
BEGIN
    SET NOCOUNT ON;
    -- Validate property type (case-insensitive) to keep consistent with update procedure
    IF UPPER(@PropertyType) NOT IN ('FLAT','HOUSE','ROOM','APARTMENT','STUDIO','VILLA','COMMERCIAL','CONDO','DUPLEX')
    BEGIN
        RAISERROR ('Invalid property type. Must be one of: Flat, House, Room, Apartment, Studio, Villa, Commercial, Condo, Duplex.', 16, 1);
        RETURN;
    END
    INSERT INTO properties (
        owner_id, title, address, property_type,
        bedrooms, bathrooms, area, rent_amount,
        deposit_amount, description, status, created_at
    )
    VALUES (
        @OwnerId, @Title, @Address, @PropertyType,
        @Bedrooms, @Bathrooms, @Area, @RentAmount,
        @DepositAmount, @Description, @Status, GETDATE()
    );
    SELECT SCOPE_IDENTITY() as PropertyId;
END;
GO

CREATE PROCEDURE sp_UpdateProperty
    @PropertyId INT,
    @Title NVARCHAR(200),
    @Address NVARCHAR(500),
    @PropertyType NVARCHAR(50),
    @Bedrooms INT,
    @Bathrooms INT,
    @Area FLOAT,
    @RentAmount FLOAT,
    @DepositAmount FLOAT = NULL,
    @Description NTEXT = NULL,
    @Status NVARCHAR(50)
AS
BEGIN
    SET NOCOUNT ON;

    -- Validate property exists
    IF NOT EXISTS (SELECT 1 FROM properties WHERE id = @PropertyId)
    BEGIN
        RAISERROR ('Property not found. The specified property ID does not exist.', 16, 1);
        RETURN;
    END

    -- Validate title
    IF LEN(TRIM(@Title)) = 0
    BEGIN
        RAISERROR ('Property title cannot be empty.', 16, 1);
        RETURN;
    END

    -- Validate address
    IF LEN(TRIM(@Address)) = 0
    BEGIN
        RAISERROR ('Property address cannot be empty.', 16, 1);
        RETURN;
    END

    -- Validate property type (case-insensitive) and include additional allowed types
    IF UPPER(@PropertyType) NOT IN ('FLAT','HOUSE','ROOM','APARTMENT','STUDIO','VILLA','COMMERCIAL','CONDO','DUPLEX')
    BEGIN
        RAISERROR ('Invalid property type. Must be one of: Flat, House, Room, Apartment, Studio, Villa, Commercial, Condo, Duplex.', 16, 1);
        RETURN;
    END

    -- Validate numbers
    IF @Bedrooms < 0 OR @Bathrooms < 0
    BEGIN
        RAISERROR ('Number of bedrooms and bathrooms cannot be negative.', 16, 1);
        RETURN;
    END

    IF @Area <= 0
    BEGIN
        RAISERROR ('Property area must be greater than zero.', 16, 1);
        RETURN;
    END

    IF @RentAmount <= 0
    BEGIN
        RAISERROR ('Rent amount must be greater than zero.', 16, 1);
        RETURN;
    END

    IF @DepositAmount IS NOT NULL AND @DepositAmount < 0
    BEGIN
        RAISERROR ('Deposit amount cannot be negative.', 16, 1);
        RETURN;
    END

    -- Validate status
    IF @Status NOT IN ('vacant', 'rented', 'maintenance', 'deleted')
    BEGIN
        RAISERROR ('Invalid status. Must be one of: vacant, rented, maintenance, deleted.', 16, 1);
        RETURN;
    END

    -- Check if status change is valid
    DECLARE @CurrentStatus NVARCHAR(50)
    SELECT @CurrentStatus = status FROM properties WHERE id = @PropertyId

    IF @CurrentStatus = 'rented' AND @Status = 'vacant'
    BEGIN
        IF EXISTS (SELECT 1 FROM leases WHERE property_id = @PropertyId AND status = 'active')
        BEGIN
            RAISERROR ('Cannot change status to vacant while property has an active lease.', 16, 1);
            RETURN;
        END
    END

    UPDATE properties
    SET title = @Title,
        address = @Address,
        property_type = @PropertyType,
        bedrooms = @Bedrooms,
        bathrooms = @Bathrooms,
        area = @Area,
        rent_amount = @RentAmount,
        deposit_amount = @DepositAmount,
        description = @Description,
        status = @Status,
        updated_at = GETDATE()
    WHERE id = @PropertyId;
    SELECT @@ROWCOUNT as AffectedRows;
END;
GO

CREATE PROCEDURE sp_DeleteProperty
    @PropertyId INT
AS
BEGIN
    SET NOCOUNT ON;
    UPDATE properties
    SET status = 'deleted',
        updated_at = GETDATE()
    WHERE id = @PropertyId;
    SELECT @@ROWCOUNT as AffectedRows;
END;
GO

CREATE PROCEDURE sp_GetProperty
    @PropertyId INT
AS
BEGIN
    SET NOCOUNT ON;
    SELECT * FROM properties WHERE id = @PropertyId AND status <> 'deleted';
END;
GO

CREATE PROCEDURE sp_GetAllProperties
    @OwnerId INT = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SELECT * FROM properties 
    WHERE (@OwnerId IS NULL OR owner_id = @OwnerId) 
    AND status <> 'deleted'
    ORDER BY created_at DESC;
END;
GO

-- Create Lease Management Stored Procedures
CREATE PROCEDURE sp_CreateLease
    @TenantId INT,
    @PropertyId INT,
    @StartDate DATE,
    @RentAmount FLOAT
AS
BEGIN
    SET NOCOUNT ON;
    
    -- Validate tenant exists and is active
    IF NOT EXISTS (SELECT 1 FROM users WHERE id = @TenantId AND role = 'renter' AND is_active = 1)
    BEGIN
        RAISERROR ('Invalid tenant ID. The specified tenant does not exist or is not an active renter.', 16, 1);
        RETURN;
    END
    
    -- Validate property exists and is available (treat 'available' same as 'vacant')
    IF NOT EXISTS (SELECT 1 FROM properties WHERE id = @PropertyId AND (status = 'vacant' OR status = 'available'))
    BEGIN
        RAISERROR ('Invalid property ID. The property does not exist or is not available for lease.', 16, 1);
        RETURN;
    END
    
    -- Validate rent amount
    IF @RentAmount <= 0
    BEGIN
        RAISERROR ('Invalid rent amount. Rent must be greater than zero.', 16, 1);
        RETURN;
    END
    
    -- Validate start date (allow same-day start)
    IF @StartDate < CAST(GETDATE() AS DATE)
    BEGIN
        RAISERROR ('Invalid start date. Lease cannot start in the past.', 16, 1);
        RETURN;
    END

    -- Check if tenant already has an active lease
    IF EXISTS (
        SELECT 1 FROM leases 
        WHERE tenant_id = @TenantId 
        AND status = 'active'
        AND (end_date IS NULL OR end_date >= GETDATE())
    )
    BEGIN
        RAISERROR ('Tenant already has an active lease. One tenant cannot have multiple active leases.', 16, 1);
        RETURN;
    END

    -- Check if property already has an active lease
    IF EXISTS (
        SELECT 1 FROM leases 
        WHERE property_id = @PropertyId 
        AND status = 'active'
        AND (end_date IS NULL OR end_date >= GETDATE())
    )
    BEGIN
        RAISERROR ('Property already has an active lease. Please terminate the current lease before creating a new one.', 16, 1);
        RETURN;
    END

    -- Create the lease
    INSERT INTO leases (
        tenant_id, property_id, start_date,
        rent_amount, status, created_at
    )
    VALUES (
        @TenantId, @PropertyId, @StartDate,
        @RentAmount, 'active', GETDATE()
    );

    -- Update property status to 'rented'
    UPDATE properties
    SET status = 'rented',
        updated_at = GETDATE()
    WHERE id = @PropertyId;

    COMMIT;
    
    SELECT SCOPE_IDENTITY() as LeaseId;
END;
GO

CREATE PROCEDURE sp_GetLease
    @LeaseId INT
AS
BEGIN
    SET NOCOUNT ON;
    SELECT 
        l.*,
        p.title as property_title,
        p.address as property_address,
        u.full_name as tenant_name,
        u.email as tenant_email
    FROM leases l
    INNER JOIN properties p ON l.property_id = p.id
    INNER JOIN users u ON l.tenant_id = u.id
    WHERE l.id = @LeaseId;
END;
GO

CREATE PROCEDURE sp_UpdateLease
    @LeaseId INT,
    @StartDate DATE = NULL,
    @EndDate DATE = NULL,
    @RentAmount FLOAT = NULL,
    @DepositAmount FLOAT = NULL,
    @Status NVARCHAR(20) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    UPDATE leases
    SET start_date = COALESCE(@StartDate, start_date),
        end_date = COALESCE(@EndDate, end_date),
        rent_amount = COALESCE(@RentAmount, rent_amount),
        deposit_amount = COALESCE(@DepositAmount, deposit_amount),
        status = COALESCE(@Status, status),
        updated_at = GETDATE()
    WHERE id = @LeaseId;

    -- If lease status changes to 'terminated' or 'expired', update property status
    IF @Status IN ('terminated', 'expired')
    BEGIN
        UPDATE p
        SET p.status = 'available',
            p.updated_at = GETDATE()
        FROM properties p
        INNER JOIN leases l ON p.id = l.property_id
        WHERE l.id = @LeaseId;
    END

    SELECT @@ROWCOUNT as AffectedRows;
END;
GO

CREATE PROCEDURE sp_ListLeases
    @TenantId INT = NULL,
    @PropertyId INT = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SELECT 
        l.*,
        p.title as property_title,
        p.address as property_address,
        u.full_name as tenant_name,
        u.email as tenant_email
    FROM leases l
    INNER JOIN properties p ON l.property_id = p.id
    INNER JOIN users u ON l.tenant_id = u.id
    WHERE (@TenantId IS NULL OR l.tenant_id = @TenantId)
      AND (@PropertyId IS NULL OR l.property_id = @PropertyId)
    ORDER BY l.created_at DESC;
END;
GO

CREATE PROCEDURE sp_GetActiveLeaseByProperty
    @PropertyId INT
AS
BEGIN
    SET NOCOUNT ON;
    SELECT 
        l.*,
        p.title as property_title,
        p.address as property_address,
        u.full_name as tenant_name,
        u.email as tenant_email
    FROM leases l
    INNER JOIN properties p ON l.property_id = p.id
    INNER JOIN users u ON l.tenant_id = u.id
    WHERE l.property_id = @PropertyId 
    AND l.status = 'active'
    AND (l.end_date IS NULL OR l.end_date > GETDATE());
END;
GO

CREATE PROCEDURE sp_GetLeasesByProperty
    @PropertyId INT
AS
BEGIN
    SET NOCOUNT ON;
    SELECT 
        l.*,
        p.title as property_title,
        p.address as property_address,
        u.full_name as tenant_name,
        u.email as tenant_email
    FROM leases l
    INNER JOIN properties p ON l.property_id = p.id
    INNER JOIN users u ON l.tenant_id = u.id
    WHERE l.property_id = @PropertyId 
    ORDER BY l.created_at DESC;
END;
GO

-- Property Documents Stored Procedures
CREATE OR ALTER PROCEDURE sp_AddPropertyDocument
    @PropertyId INT,
    @FileName NVARCHAR(255),
    @FilePath NVARCHAR(500),
    @ContentType NVARCHAR(100) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    INSERT INTO property_documents (property_id, file_name, file_path, content_type, uploaded_at)
    VALUES (@PropertyId, @FileName, @FilePath, @ContentType, GETDATE());
    SELECT SCOPE_IDENTITY() AS DocumentId;
END;
GO

-- Lease Invitations Stored Procedures
CREATE OR ALTER PROCEDURE sp_CreateLeaseInvitation
    @OwnerId INT,
    @RenterId INT,
    @PropertyId INT,
    @StartDate DATE,
    @RentAmount FLOAT,
    @DepositAmount FLOAT = NULL
AS
BEGIN
    SET NOCOUNT ON;

    -- Validate renter
    IF NOT EXISTS (SELECT 1 FROM users WHERE id = @RenterId AND role = 'renter' AND is_active = 1)
    BEGIN
        RAISERROR ('Invalid renter. The specified renter does not exist or is not active.', 16, 1);
        RETURN;
    END

    -- Validate property belongs to owner and is available (support legacy 'vacant' and new 'available')
    IF NOT EXISTS (SELECT 1 FROM properties WHERE id = @PropertyId AND owner_id = @OwnerId AND (status = 'vacant' OR status = 'available'))
    BEGIN
        RAISERROR ('Property is not available for invitation. It may be rented or under maintenance.', 16, 1);
        RETURN;
    END

    -- Extra guard: ensure no active lease exists (in case status is stale)
    IF EXISTS (
        SELECT 1 FROM leases 
        WHERE property_id = @PropertyId 
          AND status = 'active' 
          AND (end_date IS NULL OR end_date >= GETDATE())
    )
    BEGIN
        RAISERROR ('Property already has an active lease.', 16, 1);
        RETURN;
    END

    INSERT INTO lease_invitations (owner_id, renter_id, property_id, start_date, rent_amount, deposit_amount, status, created_at)
    VALUES (@OwnerId, @RenterId, @PropertyId, @StartDate, @RentAmount, @DepositAmount, 'pending', GETDATE());

    SELECT SCOPE_IDENTITY() AS InvitationId;
END;
GO

CREATE OR ALTER PROCEDURE sp_ListLeaseInvitationsForRenter
    @RenterId INT
AS
BEGIN
    SET NOCOUNT ON;
    SELECT li.*, p.title AS property_title, p.address AS property_address, u.full_name AS owner_name, u.email AS owner_email
    FROM lease_invitations li
    INNER JOIN properties p ON li.property_id = p.id
    INNER JOIN users u ON li.owner_id = u.id
    WHERE li.renter_id = @RenterId AND li.status = 'pending'
    ORDER BY li.created_at DESC;
END;
GO

CREATE OR ALTER PROCEDURE sp_ApproveLeaseInvitation
    @InvitationId INT
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @OwnerId INT, @RenterId INT, @PropertyId INT, @StartDate DATE, @RentAmount FLOAT, @DepositAmount FLOAT;
    SELECT @OwnerId = owner_id, @RenterId = renter_id, @PropertyId = property_id, @StartDate = start_date, @RentAmount = rent_amount, @DepositAmount = deposit_amount
    FROM lease_invitations WHERE id = @InvitationId AND status = 'pending';

    IF @OwnerId IS NULL
    BEGIN
        RAISERROR ('Invitation not found or not pending.', 16, 1);
        RETURN;
    END

    -- If start date is in the past, update it to today
    IF @StartDate < CAST(GETDATE() AS DATE)
    BEGIN
        SET @StartDate = CAST(GETDATE() AS DATE);
    END

    -- Create lease using existing validations in sp_CreateLease
    EXEC sp_CreateLease @TenantId=@RenterId, @PropertyId=@PropertyId, @StartDate=@StartDate, @RentAmount=@RentAmount;

    -- Mark invitation as approved
    UPDATE lease_invitations SET status = 'approved', updated_at = GETDATE() WHERE id = @InvitationId;
    SELECT @@ROWCOUNT AS AffectedRows;
END;
GO

CREATE OR ALTER PROCEDURE sp_RejectLeaseInvitation
    @InvitationId INT
AS
BEGIN
    SET NOCOUNT ON;
    UPDATE lease_invitations SET status = 'rejected', updated_at = GETDATE() WHERE id = @InvitationId AND status = 'pending';
    SELECT @@ROWCOUNT AS AffectedRows;
END;
GO

CREATE OR ALTER PROCEDURE sp_CancelLeaseInvitation
    @InvitationId INT
AS
BEGIN
    SET NOCOUNT ON;
    UPDATE lease_invitations SET status = 'canceled', updated_at = GETDATE() WHERE id = @InvitationId AND status IN ('pending');
    SELECT @@ROWCOUNT AS AffectedRows;
END;
GO

CREATE OR ALTER PROCEDURE sp_ListPropertyDocuments
    @PropertyId INT
AS
BEGIN
    SET NOCOUNT ON;
    SELECT id, property_id, file_name, file_path, content_type, uploaded_at
    FROM property_documents
    WHERE property_id = @PropertyId
    ORDER BY uploaded_at DESC;
END;
GO

CREATE OR ALTER PROCEDURE sp_DeletePropertyDocument
    @DocumentId INT
AS
BEGIN
    SET NOCOUNT ON;
    DELETE FROM property_documents WHERE id = @DocumentId;
    SELECT @@ROWCOUNT AS AffectedRows;
END;
GO

-- ===================== SEED DATA (Idempotent) =====================
-- This section inserts representative dummy data across all tables.
-- Safe to re-run: it checks for existing rows by natural keys/unique fields.

-- Users
IF NOT EXISTS (SELECT 1 FROM users WHERE email = 'owner@example.com')
BEGIN
    INSERT INTO users (email, username, hashed_password, full_name, role, is_active, created_at)
    VALUES (
        'owner@example.com',
        'owner1',
        '$pbkdf2-sha256$29000$690bY8w5x3gvZSyldK71/g$aO90Bc6Yt460w/7J2zqDuQ1f4N5R6uRwJonYoXRgcUk', -- ownerpass
        'Olivia Owner',
        'owner',
        1,
        GETDATE()
    );
END;

IF NOT EXISTS (SELECT 1 FROM users WHERE email = 'renter@example.com')
BEGIN
    INSERT INTO users (email, username, hashed_password, full_name, role, is_active, created_at)
    VALUES (
        'renter@example.com',
        'renter1',
        '$pbkdf2-sha256$29000$6N07Z6w15vxfC8HYe49Rag$rp/29kugh3jj/M3qcoY2kkQ/vDisaapS/bufmwENs6s', -- renterpass
        'Riley Renter',
        'renter',
        1,
        GETDATE()
    );
END;

IF NOT EXISTS (SELECT 1 FROM users WHERE email = 'admin@example.com')
BEGIN
    INSERT INTO users (email, username, hashed_password, full_name, role, is_active, created_at)
    VALUES (
        'admin@example.com',
        'admin1',
        '$pbkdf2-sha256$29000$8T4nZCyldM7ZO6fUOifkPA$cC.30SiIHXHaLT4PiNh1ltZZu4wwOozs8SdMGF9GULo', -- adminpass
        'Avery Admin',
        'admin',
        1,
        GETDATE()
    );
END;

-- Owner profile
IF NOT EXISTS (
    SELECT 1 FROM owner_profiles op
    JOIN users u ON u.id = op.user_id
    WHERE u.email = 'owner@example.com'
)
BEGIN
    DECLARE @OwnerIdSeed INT;
    SELECT @OwnerIdSeed = id FROM users WHERE email = 'owner@example.com';
    INSERT INTO owner_profiles (user_id, phone, address, company, created_at)
    VALUES (@OwnerIdSeed, '+1-555-0100', '100 Main St, Metropolis', 'ReOwn Estates', GETDATE());
END;

-- Renter profile
IF NOT EXISTS (
    SELECT 1 FROM renter_profiles rp
    JOIN users u ON u.id = rp.user_id
    WHERE u.email = 'renter@example.com'
)
BEGIN
    DECLARE @RenterIdSeed INT;
    SELECT @RenterIdSeed = id FROM users WHERE email = 'renter@example.com';
    INSERT INTO renter_profiles (user_id, phone, address, lease_start, lease_end, created_at)
    VALUES (@RenterIdSeed, '+1-555-0110', '200 Pine Ave, Metropolis', NULL, NULL, GETDATE());
END;

-- Properties (two: one vacant, one rented after lease below)
IF NOT EXISTS (SELECT 1 FROM properties WHERE title = 'Downtown Loft' AND address = '123 Market St, Metropolis')
BEGIN
    DECLARE @OwnerUserId INT; SELECT @OwnerUserId = id FROM users WHERE email = 'owner@example.com';
    INSERT INTO properties (
        owner_id, title, address, property_type, bedrooms, bathrooms, area, rent_amount, deposit_amount, description, status, created_at
    ) VALUES (
        @OwnerUserId, 'Downtown Loft', '123 Market St, Metropolis', 'Apartment', 2, 2, 950, 1500, 1500, 'Sunny loft near central park', 'vacant', GETDATE()
    );
END;

IF NOT EXISTS (SELECT 1 FROM properties WHERE title = 'Suburban House' AND address = '45 Oak Lane, Smallville')
BEGIN
    DECLARE @OwnerUserId2 INT; SELECT @OwnerUserId2 = id FROM users WHERE email = 'owner@example.com';
    INSERT INTO properties (
        owner_id, title, address, property_type, bedrooms, bathrooms, area, rent_amount, deposit_amount, description, status, created_at
    ) VALUES (
        @OwnerUserId2, 'Suburban House', '45 Oak Lane, Smallville', 'House', 3, 2, 1500, 2000, 2000, 'Cozy family home with garden', 'vacant', GETDATE()
    );
END;

-- Lease for the Suburban House (active) and update property status to 'rented'
DECLARE @PropRentedId INT = (SELECT TOP 1 id FROM properties WHERE title = 'Suburban House' AND address = '45 Oak Lane, Smallville');
DECLARE @TenantRenterId INT = (SELECT id FROM users WHERE email = 'renter@example.com');
IF @PropRentedId IS NOT NULL AND @TenantRenterId IS NOT NULL
   AND NOT EXISTS (SELECT 1 FROM leases WHERE property_id = @PropRentedId AND tenant_id = @TenantRenterId AND status = 'active')
BEGIN
    INSERT INTO leases (tenant_id, property_id, start_date, end_date, rent_amount, deposit_amount, status, created_at)
    VALUES (@TenantRenterId, @PropRentedId, CONVERT(date, DATEADD(day, 1, GETDATE())), NULL, 2000, 2000, 'active', GETDATE());

    UPDATE properties SET status = 'rented', updated_at = GETDATE() WHERE id = @PropRentedId;
END;

-- Payments for the active lease/property
DECLARE @RentedProp INT = (SELECT TOP 1 id FROM properties WHERE title = 'Suburban House');
DECLARE @RenterId INT = (SELECT id FROM users WHERE email = 'renter@example.com');
IF @RentedProp IS NOT NULL AND @RenterId IS NOT NULL
BEGIN
    IF NOT EXISTS (SELECT 1 FROM payments WHERE property_id = @RentedProp AND tenant_id = @RenterId AND payment_date >= DATEADD(month, -1, GETDATE()))
    BEGIN
        INSERT INTO payments (property_id, tenant_id, amount, payment_type, payment_method, payment_status, payment_date, created_at)
        VALUES
        (@RentedProp, @RenterId, 2000, 'rent', 'card', 'paid', DATEADD(day, -15, GETDATE()), GETDATE()),
        (@RentedProp, @RenterId, 100, 'utility', 'bank_transfer', 'paid', DATEADD(day, -10, GETDATE()), GETDATE());
    END;
END;

-- Utilities readings for both properties
DECLARE @LoftId INT = (SELECT TOP 1 id FROM properties WHERE title = 'Downtown Loft');
IF @LoftId IS NOT NULL
BEGIN
    IF NOT EXISTS (SELECT 1 FROM utilities WHERE property_id = @LoftId)
    BEGIN
        INSERT INTO utilities (property_id, utility_type, reading_date, reading_value, amount, status, created_at)
        VALUES
        (@LoftId, 'electricity', DATEADD(day, -30, GETDATE()), 120.5, 45.75, 'paid', GETDATE()),
        (@LoftId, 'water',       DATEADD(day, -28, GETDATE()), 18.2,  12.10, 'paid', GETDATE());
    END;
END;

IF @RentedProp IS NOT NULL
BEGIN
    IF NOT EXISTS (SELECT 1 FROM utilities WHERE property_id = @RentedProp)
    BEGIN
        INSERT INTO utilities (property_id, utility_type, reading_date, reading_value, amount, status, created_at)
        VALUES
        (@RentedProp, 'electricity', DATEADD(day, -32, GETDATE()), 210.0, 78.25, 'paid', GETDATE()),
        (@RentedProp, 'gas',         DATEADD(day, -29, GETDATE()), 35.4,  24.65, 'paid', GETDATE());
    END;
END;

-- Property documents
DECLARE @DocPropId INT = (SELECT TOP 1 id FROM properties WHERE title = 'Suburban House');
IF @DocPropId IS NOT NULL
BEGIN
    IF NOT EXISTS (SELECT 1 FROM property_documents WHERE property_id = @DocPropId AND file_name = 'front.jpg')
    BEGIN
        INSERT INTO property_documents (property_id, file_name, file_path, content_type, uploaded_at)
        VALUES (@DocPropId, 'front.jpg', 'uploads/property_docs/front.jpg', 'image/jpeg', GETDATE());
    END;
    IF NOT EXISTS (SELECT 1 FROM property_documents WHERE property_id = @DocPropId AND file_name = 'kitchen.jpg')
    BEGIN
        INSERT INTO property_documents (property_id, file_name, file_path, content_type, uploaded_at)
        VALUES (@DocPropId, 'kitchen.jpg', 'uploads/property_docs/kitchen.jpg', 'image/jpeg', GETDATE());
    END;
END;
