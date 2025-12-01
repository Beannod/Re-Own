USE property_manager_db;
GO

-- Drop common procedures if exist handled by CREATE OR ALTER

CREATE OR ALTER PROCEDURE dbo.sp_GetUserByEmail
    @email NVARCHAR(255)
AS
BEGIN
    SET NOCOUNT ON;
    SELECT id, email, username, hashed_password, full_name, role, is_active
    FROM dbo.users
    WHERE email = @email;
END;
GO

CREATE OR ALTER PROCEDURE dbo.sp_GetUserById
    @UserId INT
AS
BEGIN
    SET NOCOUNT ON;
    SELECT id, email, username, full_name, role, is_active
    FROM dbo.users
    WHERE id = @UserId;
END;
GO

CREATE OR ALTER PROCEDURE dbo.sp_GetAllProperties
    @OwnerId INT = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SELECT p.id, p.owner_id, p.title, p.description, p.address, p.city, p.state, p.zip_code, p.country,
        p.property_type, p.status,
    p.monthly_rent AS monthly_rent,
    p.monthly_rent AS rent_amount,
    p.security_deposit, p.available_from, p.created_at, p.updated_at,
    0 AS bedrooms,
    0.00 AS bathrooms,
    0.00 AS area,
        u.email AS owner_email, u.full_name AS owner_name
    FROM dbo.properties p
    JOIN dbo.users u ON p.owner_id = u.id
    WHERE (@OwnerId IS NULL OR p.owner_id = @OwnerId)
    ORDER BY p.id;
END;
GO

CREATE OR ALTER PROCEDURE dbo.sp_GetPropertiesByOwner
    @owner_id INT
AS
BEGIN
    SET NOCOUNT ON;
    SELECT p.id, p.owner_id, p.title, p.description, p.address, p.city, p.state, p.zip_code, p.country,
        p.property_type, p.status,
    p.monthly_rent AS monthly_rent,
    p.monthly_rent AS rent_amount,
    p.security_deposit, p.available_from, p.created_at, p.updated_at,
    0 AS bedrooms,
    0.00 AS bathrooms,
    0.00 AS area,
        u.email as owner_email, u.full_name as owner_name
    FROM dbo.properties p
    JOIN dbo.users u ON p.owner_id = u.id
    WHERE p.owner_id = @owner_id;
END;
GO

CREATE OR ALTER PROCEDURE dbo.sp_GetPropertyOccupancyReport
    @owner_id INT = NULL,
    @start_date DATE = NULL,
    @end_date DATE = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SELECT
        CAST(p.id AS NVARCHAR(50)) AS property_id,
        ISNULL(p.title, '') as title,
        ISNULL(p.address, '') as address,
        ISNULL(p.property_type, '') as property_type,
        CASE UPPER(ISNULL(p.status, 'Available'))
            WHEN 'AVAILABLE' THEN 'Available'
            WHEN 'OCCUPIED' THEN 'Occupied'
            WHEN 'UNDER MAINTENANCE' THEN 'Under Maintenance'
            WHEN 'VACANT' THEN 'vacant'
            WHEN 'RENTED' THEN 'rented'
            WHEN 'MAINTENANCE' THEN 'maintenance'
            ELSE 'Available'
        END as status,
        CAST(l.tenant_id AS NVARCHAR(50)) as tenant_id,
        CONVERT(NVARCHAR(10), l.start_date, 120) as start_date,
        CONVERT(NVARCHAR(10), l.end_date, 120) as end_date,
        CASE
            WHEN l.is_active = 1 THEN 'Occupied'
            ELSE 'Available'
        END as occupancy_status,
        ISNULL(u.full_name, '') as tenant_name,
        ISNULL(u.email, '') as tenant_email
    , p.monthly_rent AS monthly_rent
    , p.monthly_rent AS rent_amount
    , 0 AS bedrooms
    , 0.00 AS bathrooms
    , 0.00 AS area
    FROM dbo.properties p
    LEFT JOIN dbo.leases l ON l.property_id = p.id
        AND l.is_active = 1
        AND (@start_date IS NULL OR l.start_date >= @start_date)
        AND (@end_date IS NULL OR l.end_date <= @end_date)
    LEFT JOIN dbo.users u ON l.tenant_id = u.id
    WHERE (@owner_id IS NULL OR p.owner_id = @owner_id)
    ORDER BY p.id;
END;
GO

CREATE OR ALTER PROCEDURE dbo.sp_ListUtilities
    @PropertyId INT = NULL,
    @TenantId INT = NULL
AS
BEGIN
    SET NOCOUNT ON;
    -- Return column names and types that the API expects: utility_type, amount, status
    SELECT
        ut.id,
        ut.lease_id,
        COALESCE(l.property_id, ut.property_id) AS property_id,
        l.tenant_id,
        -- API expects 'utility_type' (string). Map from utilities_base.name or ut.utility_type
        ISNULL( COALESCE(ub.name, ut.utility_type), '') AS utility_type,
        ut.reading_date,
        -- reading_value preserved for diagnostic use
        ISNULL(ut.reading_value, 0) AS reading_value,
        ut.rate_at_reading,
        -- API expects 'amount' (decimal). Prefer total_amount then amount
        ISNULL(CAST(COALESCE(ut.total_amount, ut.amount) AS DECIMAL(18,2)), 0.00) AS amount,
        -- API expects 'status' (string). Prefer payment_status then status
        ISNULL(COALESCE(ut.payment_status, ut.status), 'unknown') AS status,
        ut.created_at,
        ut.updated_at
    FROM dbo.utilities ut
    LEFT JOIN dbo.utilities_base ub ON ut.utility_base_id = ub.id
    LEFT JOIN dbo.leases l ON ut.lease_id = l.id
    WHERE (@PropertyId IS NULL OR COALESCE(l.property_id, ut.property_id) = @PropertyId)
        AND (@TenantId IS NULL OR l.tenant_id = @TenantId)
    ORDER BY ut.reading_date DESC;
END;
GO

CREATE OR ALTER PROCEDURE dbo.sp_GetLeasesByTenant
    @tenant_id INT
AS
BEGIN
    SET NOCOUNT ON;
    SELECT l.*, p.title as property_title, p.address
    FROM dbo.leases l
    JOIN dbo.properties p ON l.property_id = p.id
    WHERE l.tenant_id = @tenant_id AND l.is_active = 1;
END;
GO

CREATE OR ALTER PROCEDURE dbo.sp_CreatePayment
    @LeaseId INT = NULL,
    @PropertyId INT = NULL,
    @TenantId INT = NULL,
    @PaymentType NVARCHAR(50),
    @PaymentMethod NVARCHAR(50),
    @Amount DECIMAL(10,2),
    @PaymentDate DATE,
    @PaymentStatus NVARCHAR(50) = 'completed',
    @ReferenceNumber NVARCHAR(100) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    -- If lease not provided, attempt to resolve from property or tenant
    IF @LeaseId IS NULL
    BEGIN
        IF @PropertyId IS NOT NULL
        BEGIN
            SELECT TOP 1 @LeaseId = id FROM dbo.leases WHERE property_id = @PropertyId ORDER BY created_at DESC;
        END
        ELSE IF @TenantId IS NOT NULL
        BEGIN
            SELECT TOP 1 @LeaseId = id FROM dbo.leases WHERE tenant_id = @TenantId ORDER BY created_at DESC;
        END
    END

    -- Insert allowing lease_id to be NULL (payments can be linked directly to property/tenant)
    INSERT INTO dbo.payments (
        lease_id, property_id, tenant_id, payment_type, payment_method, amount,
        payment_date, payment_status, reference_number, created_at
    )
    OUTPUT INSERTED.id AS PaymentId
    VALUES (
        @LeaseId, @PropertyId, @TenantId, @PaymentType, @PaymentMethod, @Amount,
        @PaymentDate, @PaymentStatus, @ReferenceNumber, GETDATE()
    );
END;
GO

CREATE OR ALTER PROCEDURE dbo.sp_GetPayment
    @PaymentId INT
AS
BEGIN
    SET NOCOUNT ON;
    SELECT
        p.*,
        pr.title AS property_title,
        pr.owner_id,
        u.full_name AS tenant_name,
        u.email AS tenant_email
    FROM dbo.payments p
    LEFT JOIN dbo.leases l ON l.id = p.lease_id
    LEFT JOIN dbo.properties pr ON pr.id = COALESCE(l.property_id, p.property_id)
    LEFT JOIN dbo.users u ON u.id = COALESCE(l.tenant_id, p.tenant_id)
    WHERE p.id = @PaymentId;
END;
GO

CREATE OR ALTER PROCEDURE dbo.sp_ListPayments
    @OwnerId INT = NULL,
    @TenantId INT = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SELECT
        p.*,
        pr.title AS property_title,
        pr.owner_id,
        u.full_name AS tenant_name,
        u.email AS tenant_email
    FROM dbo.payments p
    LEFT JOIN dbo.leases l ON l.id = p.lease_id
    LEFT JOIN dbo.properties pr ON pr.id = COALESCE(l.property_id, p.property_id)
    LEFT JOIN dbo.users u ON u.id = COALESCE(l.tenant_id, p.tenant_id)
    WHERE (@OwnerId IS NULL OR pr.owner_id = @OwnerId)
        AND (@TenantId IS NULL OR COALESCE(l.tenant_id, p.tenant_id) = @TenantId)
    ORDER BY p.created_at DESC;
END;
GO

CREATE OR ALTER PROCEDURE dbo.sp_GetPaymentReport
    @OwnerId INT = NULL,
    @StartDate DATE = NULL,
    @EndDate DATE = NULL
AS
BEGIN
    SET NOCOUNT ON;
    IF @StartDate IS NULL
        SET @StartDate = DATEADD(MONTH, DATEDIFF(MONTH, 0, GETDATE()), 0);
    IF @EndDate IS NULL
        SET @EndDate = DATEADD(MONTH, 1, @StartDate);
    SELECT
        ISNULL(COUNT(DISTINCT COALESCE(l.property_id, p.property_id)), 0) as total_properties_with_payments,
        ISNULL(COUNT(DISTINCT COALESCE(l.tenant_id, p.tenant_id)), 0) as total_paying_tenants,
        ISNULL(SUM(CASE WHEN p.payment_status = 'completed' THEN p.amount ELSE 0 END), 0) as monthly_revenue,
        ISNULL(SUM(CASE WHEN p.payment_status = 'pending' THEN p.amount ELSE 0 END), 0) as pending_amount,
        ISNULL(AVG(CASE WHEN p.payment_status = 'completed' THEN p.amount ELSE NULL END), 0) as average_payment,
        ISNULL((
            SELECT TOP 1 p2.payment_type
            FROM dbo.payments p2
            LEFT JOIN dbo.leases l2 ON l2.id = p2.lease_id
            WHERE p2.payment_status = 'completed'
                AND (@OwnerId IS NULL OR COALESCE(l2.property_id, p2.property_id) IN (SELECT id FROM dbo.properties WHERE owner_id = @OwnerId))
                AND p2.payment_date BETWEEN @StartDate AND @EndDate
            GROUP BY p2.payment_type
            ORDER BY COUNT(*) DESC
        ), 'rent') as most_common_payment_type,
        ISNULL(SUM(CASE WHEN p.payment_status = 'completed' THEN 1 ELSE 0 END), 0) as completed_payments,
        ISNULL(SUM(CASE WHEN p.payment_status = 'pending' THEN 1 ELSE 0 END), 0) as pending_payments,
        ISNULL(SUM(CASE WHEN p.payment_status = 'failed' THEN 1 ELSE 0 END), 0) as failed_payments
    FROM dbo.payments p
    LEFT JOIN dbo.leases l ON l.id = p.lease_id
    LEFT JOIN dbo.properties pr ON pr.id = COALESCE(l.property_id, p.property_id)
    WHERE (@OwnerId IS NULL OR pr.owner_id = @OwnerId)
        AND p.payment_date BETWEEN @StartDate AND @EndDate;
END;
GO

CREATE OR ALTER PROCEDURE dbo.sp_GetPropertyStatuses
    @include_inactive BIT = 0
AS
BEGIN
    SET NOCOUNT ON;
    SELECT status_name, description
    FROM dbo.property_statuses
    WHERE @include_inactive = 1 OR is_active = 1
    ORDER BY status_name;
END;
GO

CREATE OR ALTER PROCEDURE dbo.sp_GetPropertyTypes
    @include_inactive BIT = 0
AS
BEGIN
    SET NOCOUNT ON;
    SELECT type_name, description
    FROM dbo.property_types
    WHERE @include_inactive = 1 OR is_active = 1
    ORDER BY type_name;
END;
GO

CREATE OR ALTER PROCEDURE dbo.sp_GetPaymentTypes
    @include_inactive BIT = 0
AS
BEGIN
    SET NOCOUNT ON;
    SELECT type_name, description
    FROM dbo.payment_types
    WHERE @include_inactive = 1 OR is_active = 1
    ORDER BY type_name;
END;
GO

CREATE OR ALTER PROCEDURE dbo.sp_GetPaymentMethods
    @include_inactive BIT = 0
AS
BEGIN
    SET NOCOUNT ON;
    SELECT method_name, description
    FROM dbo.payment_methods
    WHERE @include_inactive = 1 OR is_active = 1
    ORDER BY method_name;
END;
GO

CREATE OR ALTER PROCEDURE dbo.sp_GetPaymentStatuses
    @include_inactive BIT = 0
AS
BEGIN
    SET NOCOUNT ON;
    SELECT status_name, description
    FROM dbo.payment_statuses
    WHERE @include_inactive = 1 OR is_active = 1
    ORDER BY status_name;
END;
GO

-- New: Return users filtered by role, active flag, and optional search term
CREATE OR ALTER PROCEDURE dbo.sp_GetAllUsers
    @Role NVARCHAR(50) = NULL,
    @IsActive BIT = NULL,
    @SearchTerm NVARCHAR(255) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SELECT
        u.id,
        u.email,
        u.username,
        u.full_name,
        u.role,
        ISNULL(u.is_active, 0) AS is_active,
        u.created_at,
        u.updated_at
    FROM dbo.users u
    WHERE (@Role IS NULL OR u.role = @Role)
      AND (@IsActive IS NULL OR u.is_active = @IsActive)
      AND (
          @SearchTerm IS NULL
          OR u.email LIKE '%' + @SearchTerm + '%'
          OR u.username LIKE '%' + @SearchTerm + '%'
          OR u.full_name LIKE '%' + @SearchTerm + '%'
      )
    ORDER BY u.id;
END;
GO

-- Return leases for a given property (used by property endpoints)
CREATE OR ALTER PROCEDURE dbo.sp_GetLeasesByProperty
    @PropertyId INT
AS
BEGIN
    SET NOCOUNT ON;
    SELECT
        l.id,
        l.property_id,
        l.tenant_id,
        CONVERT(NVARCHAR(10), l.start_date, 120) AS start_date,
        CONVERT(NVARCHAR(10), l.end_date, 120) AS end_date,
        l.monthly_rent AS rent_amount,
        l.is_active,
        u.full_name AS tenant_name,
        u.email AS tenant_email,
        p.title AS property_title,
        p.address
    FROM dbo.leases l
    LEFT JOIN dbo.users u ON l.tenant_id = u.id
    LEFT JOIN dbo.properties p ON l.property_id = p.id
    WHERE l.property_id = @PropertyId;
END;
GO

-- Return single property details expected by the API (safe defaults for missing numeric columns)
CREATE OR ALTER PROCEDURE dbo.sp_GetProperty
    @PropertyId INT
AS
BEGIN
    SET NOCOUNT ON;
    SELECT
        p.id,
        p.owner_id,
        p.title,
        p.description,
        p.address,
        p.city,
        p.state,
        p.zip_code,
        p.country,
        p.property_type,
        p.status,
        p.monthly_rent AS monthly_rent,
        p.monthly_rent AS rent_amount,
        p.security_deposit,
        p.available_from,
        p.created_at,
        p.updated_at,
        0 AS bedrooms,
        0.00 AS bathrooms,
        0.00 AS area,
        u.email AS owner_email,
        u.full_name AS owner_name
    FROM dbo.properties p
    LEFT JOIN dbo.users u ON p.owner_id = u.id
    WHERE p.id = @PropertyId;
END;
GO

-- Update property: signature matches Python StoredProcedures.update_property call
CREATE OR ALTER PROCEDURE dbo.sp_UpdateProperty
    @PropertyId INT,
    @Title NVARCHAR(255),
    @Address NVARCHAR(500),
    @PropertyType NVARCHAR(100),
    @Bedrooms INT = 0,
    @Bathrooms DECIMAL(10,2) = 0.00,
    @Area DECIMAL(10,2) = 0.00,
    @RentAmount DECIMAL(18,2) = NULL,
    @SecurityDeposit DECIMAL(18,2) = NULL,
    @Description NVARCHAR(MAX) = NULL,
    @Status NVARCHAR(50) = NULL
AS
BEGIN
    SET NOCOUNT ON;

    -- properties table has security_deposit column per schema
    UPDATE dbo.properties
    SET title = ISNULL(@Title, title),
        address = ISNULL(@Address, address),
        property_type = ISNULL(@PropertyType, property_type),
        monthly_rent = ISNULL(@RentAmount, monthly_rent),
        security_deposit = ISNULL(@SecurityDeposit, security_deposit),
        description = ISNULL(@Description, description),
        status = ISNULL(@Status, status),
        updated_at = GETDATE()
    WHERE id = @PropertyId;

    SELECT @@ROWCOUNT AS AffectedRows;
END;
GO

/*
  Shim / stub procedures for callsites that expected stored procedures but
  weren't present in the canonical file. These provide safe defaults and
  avoid runtime ProgrammingError 2812 (procedure not found). They use
  CREATE OR ALTER so re-applying is idempotent.
*/

CREATE OR ALTER PROCEDURE dbo.sp_CreateLease
    @PropertyId INT,
    @TenantId INT,
    @StartDate DATE,
    @EndDate DATE = NULL,
    @MonthlyRent DECIMAL(18,2) = NULL,
    @IsActive BIT = 1
AS
BEGIN
    SET NOCOUNT ON;
    IF OBJECT_ID('dbo.leases','U') IS NOT NULL
    BEGIN
        INSERT INTO dbo.leases (property_id, tenant_id, start_date, end_date, monthly_rent, is_active, created_at)
        OUTPUT INSERTED.id AS LeaseId
        VALUES (@PropertyId, @TenantId, @StartDate, @EndDate, @MonthlyRent, @IsActive, GETDATE());
    END
    ELSE
    BEGIN
        -- Return no rows but maintain a consistent resultset shape when table is absent
        SELECT CAST(NULL AS INT) AS LeaseId WHERE 1=0;
    END
END;
GO

CREATE OR ALTER PROCEDURE dbo.sp_GetLease
    @LeaseId INT
AS
BEGIN
    SET NOCOUNT ON;
    IF OBJECT_ID('dbo.leases','U') IS NOT NULL
    BEGIN
        SELECT l.id, l.property_id, l.tenant_id, l.start_date, l.end_date, l.monthly_rent, l.is_active, l.created_at, l.updated_at
        FROM dbo.leases l
        WHERE l.id = @LeaseId;
    END
    ELSE
    BEGIN
        SELECT CAST(NULL AS INT) AS id, CAST(NULL AS INT) AS property_id, CAST(NULL AS INT) AS tenant_id,
               CAST(NULL AS DATE) AS start_date, CAST(NULL AS DATE) AS end_date, CAST(NULL AS DECIMAL(18,2)) AS monthly_rent,
               CAST(NULL AS BIT) AS is_active, CAST(NULL AS DATETIME) AS created_at, CAST(NULL AS DATETIME) AS updated_at
        WHERE 1=0;
    END
END;
GO

CREATE OR ALTER PROCEDURE dbo.sp_GetActiveLeaseByProperty
    @PropertyId INT
AS
BEGIN
    SET NOCOUNT ON;
    IF OBJECT_ID('dbo.leases','U') IS NOT NULL
    BEGIN
        SELECT TOP 1 l.id, l.property_id, l.tenant_id, l.start_date, l.end_date, l.monthly_rent, l.is_active
        FROM dbo.leases l
        WHERE l.property_id = @PropertyId AND l.is_active = 1
        ORDER BY l.start_date DESC;
    END
    ELSE
    BEGIN
        SELECT CAST(NULL AS INT) AS id, CAST(NULL AS INT) AS property_id, CAST(NULL AS INT) AS tenant_id,
               CAST(NULL AS DATE) AS start_date, CAST(NULL AS DATE) AS end_date, CAST(NULL AS DECIMAL(18,2)) AS monthly_rent,
               CAST(NULL AS BIT) AS is_active
        WHERE 1=0;
    END
END;
GO

-- Duplicate procedures removed (lines 535-605) - correct versions exist later in file

CREATE OR ALTER PROCEDURE dbo.sp_DeleteProperty
    @PropertyId INT
AS
BEGIN
    SET NOCOUNT ON;
    IF OBJECT_ID('dbo.properties','U') IS NOT NULL
    BEGIN
        UPDATE dbo.properties SET status = 'deleted', updated_at = GETDATE() WHERE id = @PropertyId;
        SELECT @@ROWCOUNT AS AffectedRows;
    END
    ELSE
    BEGIN
        SELECT CAST(0 AS INT) AS AffectedRows;
    END
END;
GO

CREATE OR ALTER PROCEDURE dbo.sp_GetOwnerProfile
    @OwnerId INT
AS
BEGIN
    SET NOCOUNT ON;
    IF OBJECT_ID('dbo.owner_profiles','U') IS NOT NULL
    BEGIN
        SELECT * FROM dbo.owner_profiles WHERE user_id = @OwnerId;
    END
    ELSE
    BEGIN
        SELECT CAST(NULL AS INT) AS user_id, CAST(NULL AS NVARCHAR(255)) AS phone, CAST(NULL AS NVARCHAR(500)) AS address, CAST(NULL AS NVARCHAR(255)) AS company WHERE 1=0;
    END
END;
GO

CREATE OR ALTER PROCEDURE dbo.sp_GetPropertyDocument
    @DocumentId INT
AS
BEGIN
    SET NOCOUNT ON;
    IF OBJECT_ID('dbo.property_documents','U') IS NOT NULL
    BEGIN
        SELECT id, property_id, filename, content_type, created_at FROM dbo.property_documents WHERE id = @DocumentId;
    END
    ELSE
    BEGIN
        SELECT CAST(NULL AS INT) AS id, CAST(NULL AS INT) AS property_id, CAST(NULL AS NVARCHAR(500)) AS filename, CAST(NULL AS NVARCHAR(255)) AS content_type, CAST(NULL AS DATETIME) AS created_at WHERE 1=0;
    END
END;
GO

CREATE OR ALTER PROCEDURE dbo.sp_GetUtility
    @UtilityId INT
AS
BEGIN
    SET NOCOUNT ON;
    IF OBJECT_ID('dbo.utilities','U') IS NOT NULL
    BEGIN
        SELECT ut.id, ut.lease_id, ub.name AS utility_type, ut.reading_date, ut.reading_value, ut.rate_at_reading, ut.total_amount AS amount, ut.payment_status AS status, ut.created_at
        FROM dbo.utilities ut
        LEFT JOIN dbo.utilities_base ub ON ut.utility_base_id = ub.id
        WHERE ut.id = @UtilityId;
    END
    ELSE
    BEGIN
        SELECT CAST(NULL AS INT) AS id, CAST(NULL AS INT) AS lease_id, CAST(NULL AS NVARCHAR(255)) AS utility_type, CAST(NULL AS DATETIME) AS reading_date, CAST(NULL AS DECIMAL(18,2)) AS reading_value, CAST(NULL AS DECIMAL(18,2)) AS rate_at_reading, CAST(NULL AS DECIMAL(18,2)) AS amount, CAST(NULL AS NVARCHAR(50)) AS status, CAST(NULL AS DATETIME) AS created_at WHERE 1=0;
    END
END;
GO

-- Additional shims to satisfy application callsites (minimal safe implementations)
CREATE OR ALTER PROCEDURE dbo.sp_CreateUser
    @Email NVARCHAR(255),
    @Username NVARCHAR(50),
    @HashedPassword NVARCHAR(255),
    @FullName NVARCHAR(100),
    @Role NVARCHAR(20)
AS
BEGIN
    SET NOCOUNT ON;
    IF OBJECT_ID('dbo.users','U') IS NOT NULL
    BEGIN
        INSERT INTO dbo.users (email, username, hashed_password, full_name, role, created_at)
        OUTPUT INSERTED.id AS UserId
        VALUES (@Email, @Username, @HashedPassword, @FullName, @Role, GETDATE());
    END
    ELSE
    BEGIN
        SELECT CAST(NULL AS INT) AS UserId WHERE 1=0;
    END
END;
GO

CREATE OR ALTER PROCEDURE dbo.sp_SetUserPasswordHashed
    @UserId INT,
    @HashedPassword NVARCHAR(255)
AS
BEGIN
    SET NOCOUNT ON;
    IF OBJECT_ID('dbo.users','U') IS NOT NULL
    BEGIN
        UPDATE dbo.users SET hashed_password = @HashedPassword, updated_at = GETDATE() WHERE id = @UserId;
        SELECT @@ROWCOUNT AS AffectedRows;
    END
    ELSE
    BEGIN
        SELECT CAST(0 AS INT) AS AffectedRows;
    END
END;
GO

CREATE OR ALTER PROCEDURE dbo.sp_UpdateUser
    @UserId INT,
    @Email NVARCHAR(255),
    @Username NVARCHAR(50),
    @FullName NVARCHAR(100),
    @Role NVARCHAR(20)
AS
BEGIN
    SET NOCOUNT ON;
    IF OBJECT_ID('dbo.users','U') IS NOT NULL
    BEGIN
        UPDATE dbo.users SET email = ISNULL(@Email, email), username = ISNULL(@Username, username), full_name = ISNULL(@FullName, full_name), role = ISNULL(@Role, role), updated_at = GETDATE() WHERE id = @UserId;
        SELECT @@ROWCOUNT AS AffectedRows;
    END
    ELSE
    BEGIN
        SELECT CAST(0 AS INT) AS AffectedRows;
    END
END;
GO

CREATE OR ALTER PROCEDURE dbo.sp_CreateProperty
    @OwnerId INT,
    @Title NVARCHAR(100),
    @Address NVARCHAR(255),
    @PropertyType NVARCHAR(50),
    @Bedrooms INT = 0,
    @Bathrooms DECIMAL(10,2) = 0.00,
    @Area DECIMAL(10,2) = 0.00,
    @RentAmount DECIMAL(18,2) = NULL,
    @DepositAmount DECIMAL(18,2) = NULL,
    @Description NVARCHAR(MAX) = NULL,
    @Status NVARCHAR(50) = 'Available'
AS
BEGIN
    SET NOCOUNT ON;
    IF OBJECT_ID('dbo.properties','U') IS NOT NULL
    BEGIN
        INSERT INTO dbo.properties (owner_id, title, address, city, state, zip_code, country, property_type, status, monthly_rent, security_deposit, available_from, description, created_at)
        OUTPUT INSERTED.id AS PropertyId
        VALUES (@OwnerId, @Title, @Address, 'Unknown', 'Unknown', '00000', 'Unknown', @PropertyType, @Status, ISNULL(@RentAmount,0), ISNULL(@DepositAmount,0), NULL, @Description, GETDATE());
    END
    ELSE
    BEGIN
        SELECT CAST(NULL AS INT) AS PropertyId WHERE 1=0;
    END
END;
GO

CREATE OR ALTER PROCEDURE dbo.sp_AddPropertyDocument
    @PropertyId INT,
    @FileName NVARCHAR(500),
    @FilePath NVARCHAR(1000),
    @ContentType NVARCHAR(255) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    IF OBJECT_ID('dbo.property_documents','U') IS NOT NULL
    BEGIN
        INSERT INTO dbo.property_documents (property_id, filename, content_type, created_at)
        OUTPUT INSERTED.id AS DocumentId
        VALUES (@PropertyId, @FileName, ISNULL(@ContentType,''), GETDATE());
    END
    ELSE
    BEGIN
        SELECT CAST(NULL AS INT) AS DocumentId WHERE 1=0;
    END
END;
GO

CREATE OR ALTER PROCEDURE dbo.sp_ListPropertyDocuments
    @PropertyId INT
AS
BEGIN
    SET NOCOUNT ON;
    IF OBJECT_ID('dbo.property_documents','U') IS NOT NULL
    BEGIN
        SELECT id, property_id, filename, content_type, created_at FROM dbo.property_documents WHERE property_id = @PropertyId;
    END
    ELSE
    BEGIN
        SELECT CAST(NULL AS INT) AS id, CAST(NULL AS INT) AS property_id, CAST(NULL AS NVARCHAR(500)) AS filename, CAST(NULL AS NVARCHAR(255)) AS content_type, CAST(NULL AS DATETIME) AS created_at WHERE 1=0;
    END
END;
GO

CREATE OR ALTER PROCEDURE dbo.sp_DeletePropertyDocument
    @DocumentId INT
AS
BEGIN
    SET NOCOUNT ON;
    IF OBJECT_ID('dbo.property_documents','U') IS NOT NULL
    BEGIN
        DELETE FROM dbo.property_documents WHERE id = @DocumentId;
        SELECT @@ROWCOUNT AS AffectedRows;
    END
    ELSE
    BEGIN
        SELECT CAST(0 AS INT) AS AffectedRows;
    END
END;
GO

CREATE OR ALTER PROCEDURE dbo.sp_CreateOwnerProfile
    @UserId INT,
    @Phone NVARCHAR(50) = NULL,
    @Address NVARCHAR(500) = NULL,
    @Company NVARCHAR(200) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    IF OBJECT_ID('dbo.owner_profiles','U') IS NOT NULL
    BEGIN
        IF EXISTS (SELECT 1 FROM dbo.owner_profiles WHERE user_id = @UserId)
        BEGIN
            UPDATE dbo.owner_profiles SET company_name = ISNULL(@Company, company_name), contact_number = ISNULL(@Phone, contact_number), address = ISNULL(@Address, address), updated_at = GETDATE() WHERE user_id = @UserId;
            SELECT @@ROWCOUNT AS AffectedRows;
        END
        ELSE
        BEGIN
            INSERT INTO dbo.owner_profiles (user_id, company_name, contact_number, address, created_at)
            OUTPUT INSERTED.id AS ProfileId
            VALUES (@UserId, @Company, @Phone, @Address, GETDATE());
        END
    END
    ELSE
    BEGIN
        SELECT CAST(0 AS INT) AS AffectedRows;
    END
END;
GO

CREATE OR ALTER PROCEDURE dbo.sp_UpdateOwnerProfile
    @UserId INT,
    @Phone NVARCHAR(50) = NULL,
    @Address NVARCHAR(500) = NULL,
    @Company NVARCHAR(200) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    IF OBJECT_ID('dbo.owner_profiles','U') IS NOT NULL
    BEGIN
        UPDATE dbo.owner_profiles SET company_name = ISNULL(@Company, company_name), contact_number = ISNULL(@Phone, contact_number), address = ISNULL(@Address, address), updated_at = GETDATE() WHERE user_id = @UserId;
        SELECT @@ROWCOUNT AS AffectedRows;
    END
    ELSE
    BEGIN
        SELECT CAST(0 AS INT) AS AffectedRows;
    END
END;
GO

CREATE OR ALTER PROCEDURE dbo.sp_CreateRenterProfile
    @UserId INT,
    @Phone NVARCHAR(50) = NULL,
    @Address NVARCHAR(500) = NULL,
    @LeaseStart DATE = NULL,
    @LeaseEnd DATE = NULL
AS
BEGIN
    SET NOCOUNT ON;
    IF OBJECT_ID('dbo.renter_profiles','U') IS NOT NULL
    BEGIN
        IF EXISTS (SELECT 1 FROM dbo.renter_profiles WHERE user_id = @UserId)
        BEGIN
            UPDATE dbo.renter_profiles SET phone_number = ISNULL(@Phone, phone_number), current_address = ISNULL(@Address, current_address), updated_at = GETDATE() WHERE user_id = @UserId;
            SELECT @@ROWCOUNT AS AffectedRows;
        END
        ELSE
        BEGIN
            INSERT INTO dbo.renter_profiles (user_id, phone_number, current_address, created_at)
            OUTPUT INSERTED.id AS ProfileId
            VALUES (@UserId, @Phone, @Address, GETDATE());
        END
    END
    ELSE
    BEGIN
        SELECT CAST(0 AS INT) AS AffectedRows;
    END
END;
GO

CREATE OR ALTER PROCEDURE dbo.sp_GetRenterProfile
    @UserId INT
AS
BEGIN
    SET NOCOUNT ON;
    IF OBJECT_ID('dbo.renter_profiles','U') IS NOT NULL
    BEGIN
        SELECT * FROM dbo.renter_profiles WHERE user_id = @UserId;
    END
    ELSE
    BEGIN
        SELECT CAST(NULL AS INT) AS user_id, CAST(NULL AS NVARCHAR(100)) AS emergency_contact, CAST(NULL AS NVARCHAR(50)) AS phone_number, CAST(NULL AS NVARCHAR(500)) AS current_address WHERE 1=0;
    END
END;
GO

CREATE OR ALTER PROCEDURE dbo.sp_CreateUtilityReading
    @PropertyId INT,
    @UtilityType NVARCHAR(255),
    @ReadingDate DATE,
    @ReadingValue DECIMAL(18,2),
    @Amount DECIMAL(18,2),
    @Status NVARCHAR(50)
AS
BEGIN
    SET NOCOUNT ON;
    -- Attempt to resolve lease for property; if not found we'll set lease_id NULL but still insert property_id
    DECLARE @LeaseId INT = (SELECT TOP 1 id FROM dbo.leases WHERE property_id = @PropertyId ORDER BY created_at DESC);
    IF OBJECT_ID('dbo.utilities','U') IS NOT NULL
    BEGIN
        INSERT INTO dbo.utilities (lease_id, property_id, utility_base_id, utility_type, reading_date, reading_value, rate_at_reading, total_amount, amount, payment_status, created_at)
        OUTPUT INSERTED.id AS UtilityId
        VALUES (@LeaseId, @PropertyId, 1, @UtilityType, @ReadingDate, @ReadingValue, 0, ISNULL(@Amount,0), ISNULL(@Amount,0), ISNULL(@Status,'pending'), GETDATE());
    END
    ELSE
    BEGIN
        SELECT CAST(NULL AS INT) AS UtilityId WHERE 1=0;
    END
END;
GO

CREATE OR ALTER PROCEDURE dbo.sp_UpdateUtilityReading
    @UtilityId INT,
    @ReadingValue DECIMAL(18,2),
    @Amount DECIMAL(18,2),
    @Status NVARCHAR(50)
AS
BEGIN
    SET NOCOUNT ON;
    IF OBJECT_ID('dbo.utilities','U') IS NOT NULL
    BEGIN
        UPDATE dbo.utilities SET reading_value = ISNULL(@ReadingValue, reading_value), total_amount = ISNULL(@Amount, total_amount), amount = ISNULL(@Amount, amount), payment_status = ISNULL(@Status, payment_status), status = ISNULL(@Status, status), updated_at = GETDATE() WHERE id = @UtilityId;
        SELECT @@ROWCOUNT AS AffectedRows;
    END
    ELSE
    BEGIN
        SELECT CAST(0 AS INT) AS AffectedRows;
    END
END;
GO

CREATE OR ALTER PROCEDURE dbo.sp_GetUtilityConsumptionReport
    @PropertyId INT = NULL,
    @UtilityType NVARCHAR(255) = NULL,
    @StartDate DATE = NULL,
    @EndDate DATE = NULL
AS
BEGIN
    SET NOCOUNT ON;
        SELECT u.id, u.lease_id, COALESCE(ub.name, u.utility_type) AS utility_type, u.reading_date, u.reading_value, COALESCE(u.total_amount, u.amount) AS amount, COALESCE(u.payment_status, u.status) AS status
        FROM dbo.utilities u
        LEFT JOIN dbo.utilities_base ub ON u.utility_base_id = ub.id
        LEFT JOIN dbo.leases l ON u.lease_id = l.id
        WHERE (@PropertyId IS NULL OR COALESCE(l.property_id, u.property_id) = @PropertyId)
            AND (@UtilityType IS NULL OR COALESCE(ub.name, u.utility_type) = @UtilityType)
            AND (@StartDate IS NULL OR u.reading_date >= @StartDate)
            AND (@EndDate IS NULL OR u.reading_date <= @EndDate)
        ORDER BY u.reading_date DESC;
END;
GO

CREATE OR ALTER PROCEDURE dbo.sp_ListLeases
    @TenantId INT = NULL,
    @UnitId INT = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SELECT l.id, l.property_id AS unit_id, l.tenant_id, CONVERT(NVARCHAR(10), l.start_date, 120) AS start_date, CONVERT(NVARCHAR(10), l.end_date, 120) AS end_date, l.monthly_rent AS rent_amount, l.security_deposit AS deposit_amount, l.is_active, l.created_at
    FROM dbo.leases l
    WHERE (@TenantId IS NULL OR l.tenant_id = @TenantId)
      AND (@UnitId IS NULL OR l.property_id = @UnitId)
    ORDER BY l.created_at DESC;
END;
GO

CREATE OR ALTER PROCEDURE dbo.sp_UpdateLease
    @LeaseId INT,
    @StartDate DATE = NULL,
    @EndDate DATE = NULL,
    @RentAmount DECIMAL(18,2) = NULL,
    @DepositAmount DECIMAL(18,2) = NULL,
    @Status NVARCHAR(50) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    IF OBJECT_ID('dbo.leases','U') IS NOT NULL
    BEGIN
        UPDATE dbo.leases SET start_date = ISNULL(@StartDate, start_date), end_date = ISNULL(@EndDate, end_date), monthly_rent = ISNULL(@RentAmount, monthly_rent), security_deposit = ISNULL(@DepositAmount, security_deposit), is_active = CASE WHEN @Status = 'active' THEN 1 WHEN @Status = 'terminated' THEN 0 ELSE is_active END, updated_at = GETDATE() WHERE id = @LeaseId;
        SELECT @@ROWCOUNT AS AffectedRows;
    END
    ELSE
    BEGIN
        SELECT CAST(0 AS INT) AS AffectedRows;
    END
END;
GO

CREATE OR ALTER PROCEDURE dbo.sp_UpdatePaymentStatus
    @PaymentId INT,
    @PaymentStatus NVARCHAR(50)
AS
BEGIN
    SET NOCOUNT ON;
    IF OBJECT_ID('dbo.payments','U') IS NOT NULL
    BEGIN
        UPDATE dbo.payments SET payment_status = @PaymentStatus, updated_at = GETDATE() WHERE id = @PaymentId;
        SELECT @@ROWCOUNT AS AffectedRows;
    END
    ELSE
    BEGIN
        SELECT CAST(0 AS INT) AS AffectedRows;
    END
END;
GO

CREATE OR ALTER PROCEDURE dbo.sp_UpdateRenterProfile
    @UserId INT,
    @Phone NVARCHAR(50) = NULL,
    @Address NVARCHAR(500) = NULL,
    @LeaseStart DATE = NULL,
    @LeaseEnd DATE = NULL
AS
BEGIN
    SET NOCOUNT ON;
    IF OBJECT_ID('dbo.renter_profiles','U') IS NOT NULL
    BEGIN
        UPDATE dbo.renter_profiles SET phone_number = ISNULL(@Phone, phone_number), current_address = ISNULL(@Address, current_address), updated_at = GETDATE() WHERE user_id = @UserId;
        SELECT @@ROWCOUNT AS AffectedRows;
    END
    ELSE
    BEGIN
        SELECT CAST(0 AS INT) AS AffectedRows;
    END
END;
GO

-- Improved lease and invitation procedures (override earlier shims when applied)
CREATE OR ALTER PROCEDURE dbo.sp_CreateLease
    @TenantId INT,
    @PropertyId INT,
    @StartDate DATE,
    @EndDate DATE = NULL,
    @RentAmount DECIMAL(18,2) = NULL,
    @DepositAmount DECIMAL(18,2) = NULL,
    @Status NVARCHAR(50) = 'active'
AS
BEGIN
    SET NOCOUNT ON;
    -- Validate tenant exists and is renter
    IF NOT EXISTS (SELECT 1 FROM dbo.users WHERE id = @TenantId AND role = 'renter')
    BEGIN
        RAISERROR('Invalid tenant ID', 16, 1);
        RETURN;
    END

    -- Validate property exists
    IF NOT EXISTS (SELECT 1 FROM dbo.properties WHERE id = @PropertyId)
    BEGIN
        RAISERROR('Invalid property ID', 16, 1);
        RETURN;
    END

    -- Check for an active lease on the property
    IF EXISTS (SELECT 1 FROM dbo.leases WHERE property_id = @PropertyId AND is_active = 1)
    BEGIN
        RAISERROR('Property already has an active lease', 16, 1);
        RETURN;
    END

    INSERT INTO dbo.leases (property_id, tenant_id, start_date, end_date, monthly_rent, security_deposit, is_active, created_at)
    OUTPUT INSERTED.id AS LeaseId
    VALUES (@PropertyId, @TenantId, @StartDate, @EndDate, @RentAmount, ISNULL(@DepositAmount, 0), CASE WHEN @Status = 'active' THEN 1 ELSE 0 END, GETDATE());
END;
GO

CREATE OR ALTER PROCEDURE dbo.sp_GetLease
    @LeaseId INT
AS
BEGIN
    SET NOCOUNT ON;
    SELECT l.id, l.property_id, l.tenant_id, CONVERT(NVARCHAR(10), l.start_date, 120) AS start_date,
           CONVERT(NVARCHAR(10), l.end_date, 120) AS end_date, l.monthly_rent AS rent_amount,
           l.security_deposit AS deposit_amount, l.is_active AS is_active, l.created_at, l.updated_at
    FROM dbo.leases l
    WHERE l.id = @LeaseId;
END;
GO

CREATE OR ALTER PROCEDURE dbo.sp_GetActiveLeaseByProperty
    @PropertyId INT
AS
BEGIN
    SET NOCOUNT ON;
    SELECT TOP 1 l.id, l.property_id, l.tenant_id, CONVERT(NVARCHAR(10), l.start_date, 120) AS start_date,
        CONVERT(NVARCHAR(10), l.end_date, 120) AS end_date, l.monthly_rent AS rent_amount, l.security_deposit AS deposit_amount, l.is_active
    FROM dbo.leases l
    WHERE l.property_id = @PropertyId AND l.is_active = 1
    ORDER BY l.start_date DESC;
END;
GO

CREATE OR ALTER PROCEDURE dbo.sp_CreateLeaseInvitation
    @OwnerId INT,
    @RenterId INT,
    @PropertyId INT,
    @StartDate DATE,
    @RentAmount DECIMAL(18,2),
    @DepositAmount DECIMAL(18,2) = NULL
AS
BEGIN
    SET NOCOUNT ON;

    -- Resolve renter email
    DECLARE @TenantEmail NVARCHAR(255) = (SELECT email FROM dbo.users WHERE id = @RenterId);
    IF @TenantEmail IS NULL
    BEGIN
        RAISERROR('Invalid renter id', 16, 1);
        RETURN;
    END

    -- Validate property exists
    IF NOT EXISTS (SELECT 1 FROM dbo.properties WHERE id = @PropertyId)
    BEGIN
        RAISERROR('Invalid property id', 16, 1);
        RETURN;
    END

    -- Create invitation code and expire window (14 days)
    DECLARE @InvitationCode NVARCHAR(100) = REPLACE(CONVERT(NVARCHAR(36), NEWID()), '-', '');
    DECLARE @ExpiresAt DATETIME2 = DATEADD(DAY, 14, GETDATE());

    INSERT INTO dbo.lease_invitations (property_id, tenant_email, invitation_code, is_accepted, expires_at, created_at)
    OUTPUT INSERTED.id AS InvitationId
    VALUES (@PropertyId, @TenantEmail, @InvitationCode, 0, @ExpiresAt, GETDATE());
END;
GO

CREATE OR ALTER PROCEDURE dbo.sp_ListLeaseInvitationsForRenter
    @RenterId INT
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @Email NVARCHAR(255) = (SELECT email FROM dbo.users WHERE id = @RenterId);
    IF @Email IS NULL
    BEGIN
        SELECT CAST(NULL AS INT) AS id, CAST(NULL AS INT) AS property_id, CAST(NULL AS NVARCHAR(255)) AS tenant_email, CAST(NULL AS NVARCHAR(100)) AS invitation_code, CAST(NULL AS BIT) AS is_accepted, CAST(NULL AS DATETIME2) AS expires_at WHERE 1=0;
        RETURN;
    END
    SELECT id, property_id, tenant_email, invitation_code, is_accepted, expires_at, created_at, updated_at
    FROM dbo.lease_invitations
    WHERE tenant_email = @Email AND (expires_at IS NULL OR expires_at > GETDATE());
END;
GO

CREATE OR ALTER PROCEDURE dbo.sp_ApproveLeaseInvitation
    @InvitationId INT
AS
BEGIN
    SET NOCOUNT ON;
    IF NOT EXISTS (SELECT 1 FROM dbo.lease_invitations WHERE id = @InvitationId)
    BEGIN
        RAISERROR('Invitation not found or not pending', 16, 1);
        RETURN;
    END
    UPDATE dbo.lease_invitations SET is_accepted = 1, updated_at = GETDATE() WHERE id = @InvitationId AND is_accepted = 0;
    SELECT @@ROWCOUNT AS AffectedRows;
END;
GO

CREATE OR ALTER PROCEDURE dbo.sp_RejectLeaseInvitation
    @InvitationId INT
AS
BEGIN
    SET NOCOUNT ON;
    IF NOT EXISTS (SELECT 1 FROM dbo.lease_invitations WHERE id = @InvitationId)
    BEGIN
        RAISERROR('Invitation not found or not pending', 16, 1);
        RETURN;
    END
    -- Mark as expired (set expires_at to now) to prevent reuse
    UPDATE dbo.lease_invitations SET expires_at = GETDATE(), updated_at = GETDATE() WHERE id = @InvitationId AND is_accepted = 0;
    SELECT @@ROWCOUNT AS AffectedRows;
END;
GO