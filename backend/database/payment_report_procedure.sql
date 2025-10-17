USE property_manager_db;
GO

IF OBJECT_ID('sp_GetPaymentReport', 'P') IS NOT NULL DROP PROCEDURE sp_GetPaymentReport;
GO

CREATE PROCEDURE sp_GetPaymentReport
    @OwnerId INT = NULL,
    @StartDate DATE = NULL,
    @EndDate DATE = NULL
AS
BEGIN
    SET NOCOUNT ON;
    
    -- Default to current month if no dates provided
    IF @StartDate IS NULL
        SET @StartDate = DATEADD(MONTH, DATEDIFF(MONTH, 0, GETDATE()), 0);
    IF @EndDate IS NULL
        SET @EndDate = DATEADD(MONTH, 1, @StartDate);

    -- First result set: Summary statistics
    SELECT
        ISNULL(COUNT(DISTINCT p.property_id), 0) as total_properties_with_payments,
        ISNULL(COUNT(DISTINCT p.tenant_id), 0) as total_paying_tenants,
        ISNULL(SUM(CASE WHEN p.payment_status = 'completed' THEN p.amount ELSE 0 END), 0) as monthly_revenue,
        ISNULL(SUM(CASE WHEN p.payment_status = 'pending' THEN p.amount ELSE 0 END), 0) as pending_amount,
        ISNULL(AVG(CASE WHEN p.payment_status = 'completed' THEN p.amount ELSE NULL END), 0) as average_payment,
        ISNULL((
            SELECT TOP 1 payment_type 
            FROM payments 
            WHERE payment_status = 'completed'
                AND (@OwnerId IS NULL OR property_id IN (SELECT id FROM properties WHERE owner_id = @OwnerId))
                AND payment_date BETWEEN @StartDate AND @EndDate
            GROUP BY payment_type 
            ORDER BY COUNT(*) DESC
        ), 'rent') as most_common_payment_type,
        ISNULL(SUM(CASE WHEN p.payment_status = 'completed' THEN 1 ELSE 0 END), 0) as completed_payments,
        ISNULL(SUM(CASE WHEN p.payment_status = 'pending' THEN 1 ELSE 0 END), 0) as pending_payments,
        ISNULL(SUM(CASE WHEN p.payment_status = 'failed' THEN 1 ELSE 0 END), 0) as failed_payments
    FROM payments p
    INNER JOIN properties pr ON p.property_id = pr.id
    WHERE (@OwnerId IS NULL OR pr.owner_id = @OwnerId)
        AND p.payment_date BETWEEN @StartDate AND @EndDate;

    -- Second result set: Monthly breakdown
    SELECT 
        FORMAT(p.payment_date, 'yyyy-MM') as month,
        ISNULL(SUM(CASE WHEN p.payment_status = 'completed' THEN p.amount ELSE 0 END), 0) as revenue,
        ISNULL(COUNT(*), 0) as total_payments,
        ISNULL(COUNT(DISTINCT p.tenant_id), 0) as unique_tenants
    FROM payments p
    INNER JOIN properties pr ON p.property_id = pr.id
    WHERE (@OwnerId IS NULL OR pr.owner_id = @OwnerId)
        AND p.payment_date BETWEEN @StartDate AND @EndDate
    GROUP BY FORMAT(p.payment_date, 'yyyy-MM')
    ORDER BY month;

    -- Third result set: Payment type breakdown
    SELECT 
        p.payment_type,
        ISNULL(COUNT(*), 0) as count,
        ISNULL(SUM(CASE WHEN p.payment_status = 'completed' THEN p.amount ELSE 0 END), 0) as total_amount
    FROM payments p
    INNER JOIN properties pr ON p.property_id = pr.id
    WHERE (@OwnerId IS NULL OR pr.owner_id = @OwnerId)
        AND p.payment_date BETWEEN @StartDate AND @EndDate
    GROUP BY p.payment_type
    ORDER BY count DESC;
END;
GO