USE property_manager_db;
GO

-- Update any NULL values in payments table
UPDATE payments SET
    amount = ISNULL(amount, 0),
    payment_type = ISNULL(payment_type, 'rent'),
    payment_method = ISNULL(payment_method, 'cash'),
    payment_status = ISNULL(payment_status, 'pending'),
    payment_date = ISNULL(payment_date, GETDATE()),
    created_at = ISNULL(created_at, GETDATE()),
    updated_at = ISNULL(updated_at, GETDATE())
WHERE 
    amount IS NULL 
    OR payment_type IS NULL 
    OR payment_method IS NULL 
    OR payment_status IS NULL 
    OR payment_date IS NULL
    OR created_at IS NULL;

-- Insert test payment data if table is empty
IF NOT EXISTS (SELECT TOP 1 1 FROM payments)
BEGIN
    -- Get a renter ID
    DECLARE @RenterID INT;
    SELECT TOP 1 @RenterID = id FROM users WHERE role = 'renter';

    -- Get some property IDs
    DECLARE @PropertyID1 INT, @PropertyID2 INT;
    SELECT TOP 1 @PropertyID1 = id FROM properties ORDER BY id ASC;
    SELECT TOP 1 @PropertyID2 = id FROM properties ORDER BY id DESC;

    -- Insert sample payments
    INSERT INTO payments (
        property_id,
        tenant_id,
        amount,
        payment_type,
        payment_method,
        payment_status,
        payment_date,
        created_at
    )
    VALUES
    -- This month's payments
    (@PropertyID1, @RenterID, 1200.00, 'rent', 'bank_transfer', 'completed', DATEADD(DAY, -5, GETDATE()), GETDATE()),
    (@PropertyID2, @RenterID, 800.00, 'deposit', 'card', 'completed', DATEADD(DAY, -3, GETDATE()), GETDATE()),
    (@PropertyID1, @RenterID, 150.00, 'utility', 'cash', 'pending', DATEADD(DAY, -1, GETDATE()), GETDATE()),
    
    -- Last month's payments
    (@PropertyID1, @RenterID, 1200.00, 'rent', 'bank_transfer', 'completed', DATEADD(MONTH, -1, GETDATE()), GETDATE()),
    (@PropertyID2, @RenterID, 100.00, 'utility', 'card', 'completed', DATEADD(MONTH, -1, GETDATE()), GETDATE()),
    
    -- Two months ago payments
    (@PropertyID1, @RenterID, 1200.00, 'rent', 'bank_transfer', 'completed', DATEADD(MONTH, -2, GETDATE()), GETDATE()),
    (@PropertyID2, @RenterID, 800.00, 'deposit', 'card', 'completed', DATEADD(MONTH, -2, GETDATE()), GETDATE()),
    
    -- Three months ago payments
    (@PropertyID1, @RenterID, 1200.00, 'rent', 'bank_transfer', 'completed', DATEADD(MONTH, -3, GETDATE()), GETDATE()),
    (@PropertyID2, @RenterID, 120.00, 'utility', 'cash', 'completed', DATEADD(MONTH, -3, GETDATE()), GETDATE());


END;

-- Verify there are no NULL values
SELECT 
    'NULL Values Found in Payments:' as Check_Description,
    SUM(CASE WHEN amount IS NULL THEN 1 ELSE 0 END) as Null_Amounts,
    SUM(CASE WHEN payment_type IS NULL THEN 1 ELSE 0 END) as Null_Types,
    SUM(CASE WHEN payment_method IS NULL THEN 1 ELSE 0 END) as Null_Methods,
    SUM(CASE WHEN payment_status IS NULL THEN 1 ELSE 0 END) as Null_Statuses,
    SUM(CASE WHEN payment_date IS NULL THEN 1 ELSE 0 END) as Null_Dates,
    SUM(CASE WHEN created_at IS NULL THEN 1 ELSE 0 END) as Null_CreatedAt
FROM payments;

-- Show payment summary
SELECT 
    payment_type,
    payment_status,
    COUNT(*) as count,
    SUM(amount) as total_amount,
    MIN(payment_date) as earliest_date,
    MAX(payment_date) as latest_date
FROM payments
GROUP BY payment_type, payment_status
ORDER BY payment_type, payment_status;
GO