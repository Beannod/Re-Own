USE property_manager_db;
GO

-- Drop existing procedures if they exist
IF OBJECT_ID('sp_CreatePayment', 'P') IS NOT NULL DROP PROCEDURE sp_CreatePayment;
GO
IF OBJECT_ID('sp_GetPayment', 'P') IS NOT NULL DROP PROCEDURE sp_GetPayment;
GO
IF OBJECT_ID('sp_ListPayments', 'P') IS NOT NULL DROP PROCEDURE sp_ListPayments;
GO
IF OBJECT_ID('sp_UpdatePaymentStatus', 'P') IS NOT NULL DROP PROCEDURE sp_UpdatePaymentStatus;
GO

-- Create Payment
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
    
    -- Validate property exists
    IF NOT EXISTS (SELECT 1 FROM properties WHERE id = @PropertyId)
    BEGIN
        RAISERROR('Invalid property_id', 16, 1);
        RETURN;
    END
    
    -- Validate tenant exists
    IF NOT EXISTS (SELECT 1 FROM users WHERE id = @TenantId AND role = 'renter')
    BEGIN
        RAISERROR('Invalid tenant_id', 16, 1);
        RETURN;
    END
    
    INSERT INTO payments (
        property_id, tenant_id, amount, payment_type, payment_method, 
        payment_status, payment_date, created_at
    )
    OUTPUT INSERTED.id AS PaymentId
    VALUES (
        @PropertyId, @TenantId, @Amount, @PaymentType, @PaymentMethod, 
        @PaymentStatus, @PaymentDate, GETDATE()
    );
END;
GO

-- Get Payment by ID
CREATE PROCEDURE sp_GetPayment
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
    FROM payments p
    INNER JOIN properties pr ON pr.id = p.property_id
    INNER JOIN users u ON u.id = p.tenant_id
    WHERE p.id = @PaymentId;
END;
GO

-- List Payments
CREATE PROCEDURE sp_ListPayments
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
    FROM payments p
    INNER JOIN properties pr ON pr.id = p.property_id
    INNER JOIN users u ON u.id = p.tenant_id
    WHERE (@OwnerId IS NULL OR pr.owner_id = @OwnerId)
        AND (@TenantId IS NULL OR p.tenant_id = @TenantId)
    ORDER BY p.payment_date DESC, p.created_at DESC;
END;
GO

-- Update Payment Status
CREATE PROCEDURE sp_UpdatePaymentStatus
    @PaymentId INT,
    @PaymentStatus NVARCHAR(50)
AS
BEGIN
    SET NOCOUNT ON;
    
    -- Validate payment exists
    IF NOT EXISTS (SELECT 1 FROM payments WHERE id = @PaymentId)
    BEGIN
        RAISERROR('Invalid payment_id', 16, 1);
        RETURN;
    END
    
    UPDATE payments
    SET payment_status = @PaymentStatus,
        updated_at = GETDATE()
    WHERE id = @PaymentId;
    
    SELECT @@ROWCOUNT AS AffectedRows;
END;
GO