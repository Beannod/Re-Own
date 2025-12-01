-- schema_reown.sql
-- Creates the Re-own database (if missing) and minimal tables required for registration/login

SET NOCOUNT ON;
GO

USE master;
GO
IF DB_ID('Re-own') IS NULL
BEGIN
    EXEC('CREATE DATABASE [Re-own]');
END
GO

USE [Re-own];
GO

-- Users table
IF OBJECT_ID('dbo.users','U') IS NOT NULL DROP TABLE dbo.users;
GO
CREATE TABLE dbo.users (
    id INT IDENTITY(1,1) PRIMARY KEY,
    email NVARCHAR(255) NOT NULL UNIQUE,
    username NVARCHAR(50) NOT NULL UNIQUE,
    hashed_password NVARCHAR(255) NOT NULL,
    full_name NVARCHAR(100) NOT NULL,
    role NVARCHAR(20) NOT NULL,
    is_active BIT NOT NULL DEFAULT 1,
    dark_mode BIT NOT NULL DEFAULT 0,
    notification_preferences NVARCHAR(MAX) NULL,
    created_at DATETIME2 NOT NULL DEFAULT SYSUTCDATETIME(),
    updated_at DATETIME2 NULL,
    CONSTRAINT CHK_users_role CHECK (role IN ('admin','owner','renter'))
);
GO

-- Sessions table (used by security.SessionManager persistence)
IF OBJECT_ID('dbo.sessions','U') IS NOT NULL DROP TABLE dbo.sessions;
GO
CREATE TABLE dbo.sessions (
    session_id NVARCHAR(64) NOT NULL PRIMARY KEY,
    user_id INT NOT NULL,
    created_at DATETIME2 NOT NULL DEFAULT SYSUTCDATETIME(),
    last_seen DATETIME2 NULL,
    expires_at DATETIME2 NULL,
    revoked_at DATETIME2 NULL,
    CONSTRAINT FK_sessions_user FOREIGN KEY (user_id) REFERENCES dbo.users(id)
);
GO

-- Owner profiles
IF OBJECT_ID('dbo.owner_profiles','U') IS NOT NULL DROP TABLE dbo.owner_profiles;
GO
CREATE TABLE dbo.owner_profiles (
    id INT IDENTITY(1,1) PRIMARY KEY,
    user_id INT NOT NULL UNIQUE,
    company_name NVARCHAR(200) NULL,
    contact_number NVARCHAR(50) NULL,
    address NVARCHAR(500) NULL,
    tax_id NVARCHAR(100) NULL,
    notes NVARCHAR(MAX) NULL,
    created_at DATETIME2 NOT NULL DEFAULT SYSUTCDATETIME(),
    updated_at DATETIME2 NULL,
    CONSTRAINT FK_owner_profiles_user FOREIGN KEY (user_id) REFERENCES dbo.users(id)
);
GO

-- Renter profiles
IF OBJECT_ID('dbo.renter_profiles','U') IS NOT NULL DROP TABLE dbo.renter_profiles;
GO
CREATE TABLE dbo.renter_profiles (
    id INT IDENTITY(1,1) PRIMARY KEY,
    user_id INT NOT NULL UNIQUE,
    emergency_contact NVARCHAR(100) NULL,
    phone_number NVARCHAR(50) NULL,
    current_address NVARCHAR(500) NULL,
    employment_info NVARCHAR(500) NULL,
    tenant_notes NVARCHAR(MAX) NULL,
    created_at DATETIME2 NOT NULL DEFAULT SYSUTCDATETIME(),
    updated_at DATETIME2 NULL,
    CONSTRAINT FK_renter_profiles_user FOREIGN KEY (user_id) REFERENCES dbo.users(id)
);
GO

-- Optional: minimal properties table to avoid early breakage (kept small)
IF OBJECT_ID('dbo.properties','U') IS NULL
BEGIN
    CREATE TABLE dbo.properties (
        id INT IDENTITY(1,1) PRIMARY KEY,
        owner_id INT NOT NULL,
        title NVARCHAR(200) NOT NULL,
        address NVARCHAR(500) NOT NULL,
        property_type NVARCHAR(50) NOT NULL,
        status NVARCHAR(50) NOT NULL DEFAULT 'Available',
        bedrooms INT NULL,
        bathrooms DECIMAL(10,2) NULL,
        area DECIMAL(10,2) NULL,
        monthly_rent DECIMAL(10,2) NULL,
        security_deposit DECIMAL(10,2) NULL,
        description NVARCHAR(MAX) NULL,
        created_at DATETIME2 NOT NULL DEFAULT SYSUTCDATETIME(),
        updated_at DATETIME2 NULL,
        CONSTRAINT FK_properties_owner FOREIGN KEY (owner_id) REFERENCES dbo.users(id)
    );
END
GO
