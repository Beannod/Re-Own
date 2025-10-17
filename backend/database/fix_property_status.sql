USE property_manager_db;
GO

-- Fix existing property status values to match the expected format
UPDATE properties
SET status = CASE UPPER(status)
    WHEN 'AVAILABLE' THEN 'Available'
    WHEN 'OCCUPIED' THEN 'Occupied'
    WHEN 'UNDER MAINTENANCE' THEN 'Under Maintenance'
    WHEN 'VACANT' THEN 'vacant'
    WHEN 'RENTED' THEN 'rented'
    WHEN 'MAINTENANCE' THEN 'maintenance'
    ELSE 'Available'
END;
GO