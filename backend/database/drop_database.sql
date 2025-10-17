USE master;
GO

IF EXISTS (SELECT * FROM sys.databases WHERE name = 'property_manager_db')
BEGIN
    ALTER DATABASE property_manager_db SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
    DROP DATABASE property_manager_db;
END;
GO