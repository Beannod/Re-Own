-- Create and drop database and tables
USE master;
GO

-- Create the database if missing
IF NOT EXISTS (SELECT * FROM sys.databases WHERE name = 'property_manager_db')
BEGIN
    CREATE DATABASE property_manager_db;
END
GO

USE property_manager_db;
GO
-- Ensure dependent tables are dropped first to avoid foreign key errors
-- Drop child tables in reverse dependency order (safe for repeated runs)
DROP TABLE IF EXISTS dbo.payments;
GO
DROP TABLE IF EXISTS dbo.utilities;
GO
DROP TABLE IF EXISTS dbo.utilities_base;
GO
DROP TABLE IF EXISTS dbo.leases;
GO
DROP TABLE IF EXISTS dbo.lease_invitations;
GO
DROP TABLE IF EXISTS dbo.properties;
GO
DROP TABLE IF EXISTS dbo.owner_profiles;
GO
DROP TABLE IF EXISTS dbo.renter_profiles;
GO
DROP TABLE IF EXISTS dbo.users;
GO

-- Reference tables
DROP TABLE IF EXISTS dbo.property_statuses;
GO
CREATE TABLE property_statuses (
    id INT IDENTITY(1,1) PRIMARY KEY,
    status_name NVARCHAR(50) NOT NULL UNIQUE,
    description NVARCHAR(200),
    is_active BIT DEFAULT 1,
    created_at DATETIME2 DEFAULT GETDATE(),
    updated_at DATETIME2
);
GO

DROP TABLE IF EXISTS dbo.property_types;
GO
CREATE TABLE property_types (
    id INT IDENTITY(1,1) PRIMARY KEY,
    type_name NVARCHAR(50) NOT NULL UNIQUE,
    description NVARCHAR(200),
    is_active BIT DEFAULT 1,
    created_at DATETIME2 DEFAULT GETDATE(),
    updated_at DATETIME2
);
GO

DROP TABLE IF EXISTS dbo.payment_types;
GO
CREATE TABLE payment_types (
    id INT IDENTITY(1,1) PRIMARY KEY,
    type_name NVARCHAR(50) NOT NULL UNIQUE,
    description NVARCHAR(200),
    is_active BIT DEFAULT 1,
    created_at DATETIME2 DEFAULT GETDATE(),
    updated_at DATETIME2
);
GO

DROP TABLE IF EXISTS dbo.payment_methods;
GO
CREATE TABLE payment_methods (
    id INT IDENTITY(1,1) PRIMARY KEY,
    method_name NVARCHAR(50) NOT NULL UNIQUE,
    description NVARCHAR(200),
    is_active BIT DEFAULT 1,
    created_at DATETIME2 DEFAULT GETDATE(),
    updated_at DATETIME2
);
GO

DROP TABLE IF EXISTS dbo.payment_statuses;
GO
CREATE TABLE payment_statuses (
    id INT IDENTITY(1,1) PRIMARY KEY,
    status_name NVARCHAR(50) NOT NULL UNIQUE,
    description NVARCHAR(200),
    is_active BIT DEFAULT 1,
    created_at DATETIME2 DEFAULT GETDATE(),
    updated_at DATETIME2
);
GO

-- Main tables
DROP TABLE IF EXISTS dbo.users;
GO
CREATE TABLE users (
    id INT IDENTITY(1,1) PRIMARY KEY,
    email NVARCHAR(255) NOT NULL UNIQUE,
    username NVARCHAR(50) NOT NULL UNIQUE,
    hashed_password NVARCHAR(255) NOT NULL,
    full_name NVARCHAR(100) NOT NULL,
    role NVARCHAR(20) NOT NULL,
    is_active BIT DEFAULT 1,
    dark_mode BIT DEFAULT 0,
    notification_preferences NVARCHAR(MAX) NULL,
    created_at DATETIME2 DEFAULT GETDATE(),
    updated_at DATETIME2 NULL,
    CONSTRAINT CHK_users_role CHECK (role IN ('admin', 'owner', 'renter'))
);
GO

DROP TABLE IF EXISTS dbo.properties;
GO
CREATE TABLE properties (
    id INT IDENTITY(1,1) PRIMARY KEY,
    owner_id INT NOT NULL,
    title NVARCHAR(200) NOT NULL,
    property_code NVARCHAR(50) NULL,
    description NVARCHAR(MAX),
    address NVARCHAR(500) NOT NULL,
    street NVARCHAR(200) NULL,
    city NVARCHAR(100) NULL,
    state NVARCHAR(100) NULL,
    zip_code NVARCHAR(20) NULL,
    country NVARCHAR(100) NULL,
    property_type NVARCHAR(50) NOT NULL,
    status NVARCHAR(50) NOT NULL,
    bedrooms INT NULL,
    bathrooms DECIMAL(10,2) NULL,
    area DECIMAL(10,2) NULL,
    floor_number INT NULL,
    total_floors INT NULL,
    furnishing_type NVARCHAR(50) NULL,
    parking_space NVARCHAR(100) NULL,
    balcony NVARCHAR(100) NULL,
    facing_direction NVARCHAR(20) NULL,
    age_of_property INT NULL,
    monthly_rent DECIMAL(10,2) NULL,
    rent_amount DECIMAL(10,2) NULL,
    security_deposit DECIMAL(10,2) NULL,
    deposit_amount DECIMAL(10,2) NULL,
    electricity_rate DECIMAL(10,2) NULL,
    internet_rate DECIMAL(10,2) NULL,
    water_bill DECIMAL(10,2) NULL,
    maintenance_charges DECIMAL(10,2) NULL,
    gas_charges DECIMAL(10,2) NULL,
    elevator BIT NULL,
    gym_pool_clubhouse BIT NULL,
    security_features NVARCHAR(500) NULL,
    garden_park_access BIT NULL,
    internet_provider NVARCHAR(200) NULL,
    owner_name NVARCHAR(200) NULL,
    owner_contact NVARCHAR(50) NULL,
    listing_date DATETIME2 NULL,
    lease_terms_default NVARCHAR(1000) NULL,
    available_from DATE NULL,
    created_at DATETIME2 DEFAULT GETDATE(),
    updated_at DATETIME2 NULL,
    CONSTRAINT FK_properties_owner FOREIGN KEY (owner_id) REFERENCES users(id),
    CONSTRAINT FK_properties_type FOREIGN KEY (property_type) REFERENCES property_types(type_name),
    CONSTRAINT FK_properties_status FOREIGN KEY (status) REFERENCES property_statuses(status_name)
);
GO

DROP TABLE IF EXISTS dbo.leases;
GO
CREATE TABLE leases (
    id INT IDENTITY(1,1) PRIMARY KEY,
    property_id INT NOT NULL,
    tenant_id INT NOT NULL,
    start_date DATE NOT NULL,
    end_date DATE NOT NULL,
    monthly_rent DECIMAL(10,2) NOT NULL,
    security_deposit DECIMAL(10,2) NOT NULL,
    is_active BIT DEFAULT 1,
    created_at DATETIME2 DEFAULT GETDATE(),
    updated_at DATETIME2,
    CONSTRAINT FK_leases_property FOREIGN KEY (property_id) REFERENCES properties(id),
    CONSTRAINT FK_leases_tenant FOREIGN KEY (tenant_id) REFERENCES users(id)
);
GO

DROP TABLE IF EXISTS dbo.lease_invitations;
GO
CREATE TABLE lease_invitations (
    id INT IDENTITY(1,1) PRIMARY KEY,
    property_id INT NOT NULL,
    tenant_email NVARCHAR(255) NOT NULL,
    invitation_code NVARCHAR(100) NOT NULL UNIQUE,
    is_accepted BIT DEFAULT 0,
    expires_at DATETIME2 NOT NULL,
    created_at DATETIME2 DEFAULT GETDATE(),
    updated_at DATETIME2,
    CONSTRAINT FK_lease_invitations_property FOREIGN KEY (property_id) REFERENCES properties(id)
);
GO

DROP TABLE IF EXISTS dbo.utilities_base;
GO
CREATE TABLE utilities_base (
    id INT IDENTITY(1,1) PRIMARY KEY,
    name NVARCHAR(100) NOT NULL,
    description NVARCHAR(MAX),
    rate_per_unit DECIMAL(10,2) NOT NULL,
    unit_name NVARCHAR(50) NOT NULL,
    created_at DATETIME2 DEFAULT GETDATE(),
    updated_at DATETIME2
);
GO

DROP TABLE IF EXISTS dbo.utilities;
GO
CREATE TABLE utilities (
    id INT IDENTITY(1,1) PRIMARY KEY,
    lease_id INT NULL,
    property_id INT NULL,
    utility_base_id INT NULL,
    utility_type NVARCHAR(50) NULL,
    reading_date DATE NULL,
    reading_value DECIMAL(10,2) NULL,
    rate_at_reading DECIMAL(10,2) NULL,
    total_amount DECIMAL(10,2) NULL,
    amount DECIMAL(10,2) NULL,
    payment_status NVARCHAR(50) NULL DEFAULT 'Pending',
    status NVARCHAR(50) NULL,
    created_at DATETIME2 DEFAULT GETDATE(),
    updated_at DATETIME2 NULL,
    CONSTRAINT FK_utilities_lease FOREIGN KEY (lease_id) REFERENCES leases(id),
    CONSTRAINT FK_utilities_property FOREIGN KEY (property_id) REFERENCES properties(id),
    CONSTRAINT FK_utilities_base FOREIGN KEY (utility_base_id) REFERENCES utilities_base(id),
    CONSTRAINT FK_utilities_payment_status FOREIGN KEY (payment_status) REFERENCES payment_statuses(status_name)
);
GO

DROP TABLE IF EXISTS dbo.payments;
GO
CREATE TABLE payments (
    id INT IDENTITY(1,1) PRIMARY KEY,
    lease_id INT NULL,
    property_id INT NULL,
    tenant_id INT NULL,
    payment_type NVARCHAR(50) NULL,
    payment_method NVARCHAR(50) NULL,
    amount DECIMAL(10,2) NULL,
    payment_date DATE NULL,
    payment_status NVARCHAR(50) NULL,
    reference_number NVARCHAR(100) NULL,
    created_at DATETIME2 DEFAULT GETDATE(),
    updated_at DATETIME2 NULL,
    CONSTRAINT FK_payments_lease FOREIGN KEY (lease_id) REFERENCES leases(id),
    CONSTRAINT FK_payments_property FOREIGN KEY (property_id) REFERENCES properties(id),
    CONSTRAINT FK_payments_tenant FOREIGN KEY (tenant_id) REFERENCES users(id),
    CONSTRAINT FK_payments_type FOREIGN KEY (payment_type) REFERENCES payment_types(type_name),
    CONSTRAINT FK_payments_method FOREIGN KEY (payment_method) REFERENCES payment_methods(method_name),
    CONSTRAINT FK_payments_status FOREIGN KEY (payment_status) REFERENCES payment_statuses(status_name)
);
GO

-- Profile tables
DROP TABLE IF EXISTS dbo.owner_profiles;
GO
DROP TABLE IF EXISTS dbo.renter_profiles;
GO
CREATE TABLE dbo.owner_profiles (
    id INT IDENTITY(1,1) PRIMARY KEY,
    user_id INT NOT NULL UNIQUE,
    company_name NVARCHAR(200) NULL,
    contact_number NVARCHAR(50) NULL,
    address NVARCHAR(500) NULL,
    tax_id NVARCHAR(100) NULL,
    notes NVARCHAR(MAX) NULL,
    created_at DATETIME2 DEFAULT GETDATE(),
    updated_at DATETIME2 NULL
);
GO
IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = 'FK_owner_profiles_user')
BEGIN
    ALTER TABLE dbo.owner_profiles
    ADD CONSTRAINT FK_owner_profiles_user FOREIGN KEY (user_id) REFERENCES dbo.users(id);
END;
GO

CREATE TABLE dbo.renter_profiles (
    id INT IDENTITY(1,1) PRIMARY KEY,
    user_id INT NOT NULL UNIQUE,
    emergency_contact NVARCHAR(100) NULL,
    phone_number NVARCHAR(50) NULL,
    current_address NVARCHAR(500) NULL,
    employment_info NVARCHAR(500) NULL,
    tenant_notes NVARCHAR(MAX) NULL,
    created_at DATETIME2 DEFAULT GETDATE(),
    updated_at DATETIME2 NULL
);
GO
IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = 'FK_renter_profiles_user')
BEGIN
    ALTER TABLE dbo.renter_profiles
    ADD CONSTRAINT FK_renter_profiles_user FOREIGN KEY (user_id) REFERENCES dbo.users(id);
END;
GO
