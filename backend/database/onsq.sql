-- One-shot SQL: create or update required stored procedures without dropping
-- Safe for repeated runs; uses CREATE OR ALTER to avoid existence errors

USE property_manager_db;
GO

/* ===================== Users Listing ===================== */
CREATE OR ALTER PROCEDURE sp_GetAllUsers
    @Role NVARCHAR(20) = NULL,
    @IsActive BIT = NULL,
    @SearchTerm NVARCHAR(255) = NULL
AS
BEGIN
    SET NOCOUNT ON;

    -- Validate role if provided
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

/* ===================== Utilities ===================== */
CREATE OR ALTER PROCEDURE sp_ListUtilities
    @PropertyId INT = NULL
AS
BEGIN
    SET NOCOUNT ON;

    SELECT 
        u.id,
        u.property_id,
        u.utility_type,
        u.provider_name,
        u.account_number,
        u.monthly_cost,
        u.due_date,
        u.is_active,
        u.created_at,
        u.updated_at,
        p.title as property_title
    FROM utilities u
    LEFT JOIN properties p ON u.property_id = p.id
    WHERE (@PropertyId IS NULL OR u.property_id = @PropertyId)
    ORDER BY u.property_id, u.utility_type;
END;
GO

CREATE OR ALTER PROCEDURE sp_GetUtility
    @UtilityId INT
AS
BEGIN
    SET NOCOUNT ON;

    SELECT 
        u.id,
        u.property_id,
        u.utility_type,
        u.provider_name,
        u.account_number,
        u.monthly_cost,
        u.due_date,
        u.is_active,
        u.created_at,
        u.updated_at,
        p.title as property_title
    FROM utilities u
    LEFT JOIN properties p ON u.property_id = p.id
    WHERE u.id = @UtilityId;
END;
GO

/* ===================== Leases ===================== */
CREATE OR ALTER PROCEDURE sp_CreateLease
    @TenantId INT,
    @UnitId INT,
    @StartDate DATE,
    @EndDate DATE = NULL,
    @RentAmount DECIMAL(10,2),
    @DepositAmount DECIMAL(10,2) = NULL,
    @Status NVARCHAR(20) = 'active'
AS
BEGIN
    SET NOCOUNT ON;

    IF @TenantId IS NULL OR @UnitId IS NULL OR @StartDate IS NULL OR @RentAmount IS NULL
    BEGIN
        RAISERROR('Required parameters cannot be null', 16, 1);
        RETURN;
    END

    IF NOT EXISTS (SELECT 1 FROM users WHERE id = @TenantId AND role = 'renter')
    BEGIN
        RAISERROR('Invalid tenant ID or user is not a renter', 16, 1);
        RETURN;
    END

    IF NOT EXISTS (SELECT 1 FROM properties WHERE id = @UnitId)
    BEGIN
        RAISERROR('Invalid property/unit ID', 16, 1);
        RETURN;
    END

    INSERT INTO leases (
        tenant_id, unit_id, start_date, end_date, rent_amount, deposit_amount, status, created_at
    )
    OUTPUT INSERTED.id as LeaseId
    VALUES (
        @TenantId, @UnitId, @StartDate, @EndDate, @RentAmount, @DepositAmount, @Status, GETDATE()
    );
END;
GO

CREATE OR ALTER PROCEDURE sp_GetActiveLeaseByProperty
    @PropertyId INT
AS
BEGIN
    SET NOCOUNT ON;

    SELECT TOP 1
        l.id,
        l.tenant_id,
        l.unit_id,
        l.start_date,
        l.end_date,
        l.rent_amount,
        l.deposit_amount,
        l.status,
        l.created_at,
        l.updated_at,
        u.email as tenant_email,
        u.full_name as tenant_name,
        p.title as property_title
    FROM leases l
    INNER JOIN users u ON l.tenant_id = u.id
    INNER JOIN properties p ON l.unit_id = p.id
    WHERE l.unit_id = @PropertyId 
      AND l.status = 'active'
      AND (l.end_date IS NULL OR l.end_date > GETDATE())
    ORDER BY l.start_date DESC;
END;
GO

CREATE OR ALTER PROCEDURE sp_GetLease
    @LeaseId INT
AS
BEGIN
    SET NOCOUNT ON;

    SELECT 
        l.id,
        l.tenant_id,
        l.unit_id,
        l.start_date,
        l.end_date,
        l.rent_amount,
        l.deposit_amount,
        l.status,
        l.created_at,
        l.updated_at,
        u.email as tenant_email,
        u.full_name as tenant_name,
        p.title as property_title
    FROM leases l
    INNER JOIN users u ON l.tenant_id = u.id
    INNER JOIN properties p ON l.unit_id = p.id
    WHERE l.id = @LeaseId;
END;
GO

CREATE OR ALTER PROCEDURE sp_ListLeases
    @TenantId INT = NULL,
    @UnitId INT = NULL
AS
BEGIN
    SET NOCOUNT ON;

    SELECT 
        l.id,
        l.tenant_id,
        l.unit_id,
        l.start_date,
        l.end_date,
        l.rent_amount,
        l.deposit_amount,
        l.status,
        l.created_at,
        l.updated_at,
        u.email as tenant_email,
        u.full_name as tenant_name,
        p.title as property_title
    FROM leases l
    INNER JOIN users u ON l.tenant_id = u.id
    INNER JOIN properties p ON l.unit_id = p.id
    WHERE (@TenantId IS NULL OR l.tenant_id = @TenantId)
      AND (@UnitId IS NULL OR l.unit_id = @UnitId)
    ORDER BY l.created_at DESC;
END;
GO

CREATE OR ALTER PROCEDURE sp_UpdateLease
    @LeaseId INT,
    @StartDate DATE = NULL,
    @EndDate DATE = NULL,
    @RentAmount DECIMAL(10,2) = NULL,
    @DepositAmount DECIMAL(10,2) = NULL,
    @Status NVARCHAR(20) = NULL
AS
BEGIN
    SET NOCOUNT ON;

    IF NOT EXISTS (SELECT 1 FROM leases WHERE id = @LeaseId)
    BEGIN
        RAISERROR('Lease not found', 16, 1);
        RETURN;
    END

    UPDATE leases
    SET 
        start_date = COALESCE(@StartDate, start_date),
        end_date = COALESCE(@EndDate, end_date),
        rent_amount = COALESCE(@RentAmount, rent_amount),
        deposit_amount = COALESCE(@DepositAmount, deposit_amount),
        status = COALESCE(@Status, status),
        updated_at = GETDATE()
    WHERE id = @LeaseId;

    EXEC sp_GetLease @LeaseId;
END;
GO

PRINT 'onsq.sql applied: procedures created or updated successfully.';
