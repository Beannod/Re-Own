USE master;
GO

-- Create the database if it doesn't exist
IF NOT EXISTS (SELECT * FROM sys.databases WHERE name = 'property_manager_db')
BEGIN
    CREATE DATABASE property_manager_db;
END
GO

USE property_manager_db;
GO

-- Reset all tables and procedures
IF EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[payments]') AND type in (N'U'))
BEGIN
    -- First disable all constraints
    EXEC sp_MSforeachtable "ALTER TABLE ? NOCHECK CONSTRAINT all";

    -- Drop existing tables in order
    DROP TABLE IF EXISTS payments;
    DROP TABLE IF EXISTS utilities;
    DROP TABLE IF EXISTS lease_invitations;
    DROP TABLE IF EXISTS leases;
    DROP TABLE IF EXISTS utilities_base;
    DROP TABLE IF EXISTS properties;
    DROP TABLE IF EXISTS users;
    DROP TABLE IF EXISTS payment_types;
    DROP TABLE IF EXISTS payment_methods;
    DROP TABLE IF EXISTS payment_statuses;
    DROP TABLE IF EXISTS property_types;
    DROP TABLE IF EXISTS property_statuses;
    DROP TABLE IF EXISTS settings;
END
GO