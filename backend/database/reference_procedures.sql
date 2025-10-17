USE property_manager_db;
GO

-- Get Property Statuses
IF OBJECT_ID('sp_GetPropertyStatuses', 'P') IS NOT NULL DROP PROCEDURE sp_GetPropertyStatuses;
GO

CREATE PROCEDURE sp_GetPropertyStatuses
    @include_inactive BIT = 0
AS
BEGIN
    SET NOCOUNT ON;
    SELECT status_name, description
    FROM property_statuses
    WHERE @include_inactive = 1 OR is_active = 1
    ORDER BY status_name;
END;
GO

-- Get Property Types
IF OBJECT_ID('sp_GetPropertyTypes', 'P') IS NOT NULL DROP PROCEDURE sp_GetPropertyTypes;
GO

CREATE PROCEDURE sp_GetPropertyTypes
    @include_inactive BIT = 0
AS
BEGIN
    SET NOCOUNT ON;
    SELECT type_name, description
    FROM property_types
    WHERE @include_inactive = 1 OR is_active = 1
    ORDER BY type_name;
END;
GO

-- Get Payment Types
IF OBJECT_ID('sp_GetPaymentTypes', 'P') IS NOT NULL DROP PROCEDURE sp_GetPaymentTypes;
GO

CREATE PROCEDURE sp_GetPaymentTypes
    @include_inactive BIT = 0
AS
BEGIN
    SET NOCOUNT ON;
    SELECT type_name, description
    FROM payment_types
    WHERE @include_inactive = 1 OR is_active = 1
    ORDER BY type_name;
END;
GO

-- Get Payment Methods
IF OBJECT_ID('sp_GetPaymentMethods', 'P') IS NOT NULL DROP PROCEDURE sp_GetPaymentMethods;
GO

CREATE PROCEDURE sp_GetPaymentMethods
    @include_inactive BIT = 0
AS
BEGIN
    SET NOCOUNT ON;
    SELECT method_name, description
    FROM payment_methods
    WHERE @include_inactive = 1 OR is_active = 1
    ORDER BY method_name;
END;
GO

-- Get Payment Statuses
IF OBJECT_ID('sp_GetPaymentStatuses', 'P') IS NOT NULL DROP PROCEDURE sp_GetPaymentStatuses;
GO

CREATE PROCEDURE sp_GetPaymentStatuses
    @include_inactive BIT = 0
AS
BEGIN
    SET NOCOUNT ON;
    SELECT status_name, description
    FROM payment_statuses
    WHERE @include_inactive = 1 OR is_active = 1
    ORDER BY status_name;
END;
GO