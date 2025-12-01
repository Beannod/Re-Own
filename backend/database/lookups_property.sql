-- lookups_property.sql
-- Adds property_types lookup table and stored procedures for lookups
-- Also seeds common property types for immediate UI usage

SET NOCOUNT ON;
GO

USE [Re-own];
GO

-- Create lookup table
IF OBJECT_ID('dbo.property_types','U') IS NULL
BEGIN
    CREATE TABLE dbo.property_types (
        id INT IDENTITY(1,1) PRIMARY KEY,
        type_name NVARCHAR(100) NOT NULL UNIQUE,
        description NVARCHAR(255) NULL,
        is_active BIT NOT NULL DEFAULT(1),
        display_order INT NULL,
        created_at DATETIME2 NOT NULL DEFAULT SYSUTCDATETIME(),
        updated_at DATETIME2 NULL
    );
END
GO

-- Seed common types (idempotent)
IF NOT EXISTS (SELECT 1 FROM dbo.property_types WHERE type_name = 'Apartment') INSERT INTO dbo.property_types (type_name, description, is_active, display_order) VALUES ('Apartment', NULL, 1, 10);
IF NOT EXISTS (SELECT 1 FROM dbo.property_types WHERE type_name = 'House')     INSERT INTO dbo.property_types (type_name, description, is_active, display_order) VALUES ('House', NULL, 1, 20);
IF NOT EXISTS (SELECT 1 FROM dbo.property_types WHERE type_name = 'Flat')      INSERT INTO dbo.property_types (type_name, description, is_active, display_order) VALUES ('Flat', NULL, 1, 30);
IF NOT EXISTS (SELECT 1 FROM dbo.property_types WHERE type_name = 'Commercial')INSERT INTO dbo.property_types (type_name, description, is_active, display_order) VALUES ('Commercial', NULL, 1, 40);
IF NOT EXISTS (SELECT 1 FROM dbo.property_types WHERE type_name = 'Land')      INSERT INTO dbo.property_types (type_name, description, is_active, display_order) VALUES ('Land', NULL, 1, 50);
IF NOT EXISTS (SELECT 1 FROM dbo.property_types WHERE type_name = 'Room')      INSERT INTO dbo.property_types (type_name, description, is_active, display_order) VALUES ('Room', NULL, 1, 60);
IF NOT EXISTS (SELECT 1 FROM dbo.property_types WHERE type_name = 'Studio')    INSERT INTO dbo.property_types (type_name, description, is_active, display_order) VALUES ('Studio', NULL, 1, 70);
IF NOT EXISTS (SELECT 1 FROM dbo.property_types WHERE type_name = 'Villa')     INSERT INTO dbo.property_types (type_name, description, is_active, display_order) VALUES ('Villa', NULL, 1, 80);
IF NOT EXISTS (SELECT 1 FROM dbo.property_types WHERE type_name = 'Condo')     INSERT INTO dbo.property_types (type_name, description, is_active, display_order) VALUES ('Condo', NULL, 1, 90);
IF NOT EXISTS (SELECT 1 FROM dbo.property_types WHERE type_name = 'Townhouse') INSERT INTO dbo.property_types (type_name, description, is_active, display_order) VALUES ('Townhouse', NULL, 1, 100);
GO

-- Drop and recreate SP: sp_GetPropertyTypes
IF OBJECT_ID('dbo.sp_GetPropertyTypes','P') IS NOT NULL DROP PROCEDURE dbo.sp_GetPropertyTypes;
GO
CREATE PROCEDURE dbo.sp_GetPropertyTypes
AS
BEGIN
    SET NOCOUNT ON;
    SELECT type_name
    FROM dbo.property_types
    WHERE is_active = 1
    ORDER BY COALESCE(display_order, 9999), type_name;
END
GO

-- Drop and recreate SP: sp_AddPropertyType
IF OBJECT_ID('dbo.sp_AddPropertyType','P') IS NOT NULL DROP PROCEDURE dbo.sp_AddPropertyType;
GO
CREATE PROCEDURE dbo.sp_AddPropertyType
    @TypeName NVARCHAR(100),
    @Description NVARCHAR(255) = NULL,
    @IsActive BIT = 1,
    @DisplayOrder INT = NULL
AS
BEGIN
    SET NOCOUNT ON;
    IF NOT EXISTS (SELECT 1 FROM dbo.property_types WHERE type_name = @TypeName)
    BEGIN
        INSERT INTO dbo.property_types (type_name, description, is_active, display_order)
        VALUES (@TypeName, @Description, @IsActive, @DisplayOrder);
        SELECT @@ROWCOUNT AS AffectedRows;
        RETURN;
    END
    -- If exists, update values
    UPDATE dbo.property_types
    SET description = @Description,
        is_active = @IsActive,
        display_order = @DisplayOrder,
        updated_at = SYSUTCDATETIME()
    WHERE type_name = @TypeName;
    SELECT @@ROWCOUNT AS AffectedRows;
END
GO
