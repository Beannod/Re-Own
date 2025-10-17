USE property_manager_db;
GO

IF OBJECT_ID('sp_GetPropertyOccupancyReport', 'P') IS NOT NULL
    DROP PROCEDURE sp_GetPropertyOccupancyReport;
GO

CREATE PROCEDURE sp_GetPropertyOccupancyReport
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
        -- Normalize property status to match expected values
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
        -- Normalize occupancy status
        CASE 
            WHEN l.status = 'active' THEN 'Occupied'
            WHEN l.status IS NULL THEN 'Available'
            ELSE 'Available'
        END as occupancy_status,
        ISNULL(u.full_name, '') as tenant_name,
        ISNULL(u.email, '') as tenant_email
    FROM properties p
    LEFT JOIN leases l ON l.property_id = p.id 
        AND l.status = 'active'
        AND (@start_date IS NULL OR l.start_date >= @start_date)
        AND (@end_date IS NULL OR l.end_date <= @end_date)
    LEFT JOIN users u ON l.tenant_id = u.id
    WHERE (@owner_id IS NULL OR p.owner_id = @owner_id)
        AND p.status != 'deleted'
    ORDER BY p.id;
END;
GO