-- stored_procedures_core.sql
-- Minimal stored procedures required for registration & login flows

SET NOCOUNT ON;
GO

USE [Re-own];
GO

-- Get user by email
IF OBJECT_ID('dbo.sp_GetUserByEmail','P') IS NOT NULL DROP PROCEDURE dbo.sp_GetUserByEmail;
GO
CREATE PROCEDURE dbo.sp_GetUserByEmail
    @Email NVARCHAR(255)
AS
BEGIN
    SET NOCOUNT ON;
    SELECT id, email, username, hashed_password, full_name, role, is_active
    FROM dbo.users
    WHERE email = @Email;
END
GO

-- Get user by id (used for preferences and /me)
IF OBJECT_ID('dbo.sp_GetUserById','P') IS NOT NULL DROP PROCEDURE dbo.sp_GetUserById;
GO
CREATE PROCEDURE dbo.sp_GetUserById
    @UserId INT
AS
BEGIN
    SET NOCOUNT ON;
    SELECT id, email, username, hashed_password, full_name, role, is_active
    FROM dbo.users
    WHERE id = @UserId;
END
GO

-- Create user
IF OBJECT_ID('dbo.sp_CreateUser','P') IS NOT NULL DROP PROCEDURE dbo.sp_CreateUser;
GO
CREATE PROCEDURE dbo.sp_CreateUser
    @Email NVARCHAR(255),
    @Username NVARCHAR(50),
    @HashedPassword NVARCHAR(255),
    @FullName NVARCHAR(100),
    @Role NVARCHAR(20)
AS
BEGIN
    SET NOCOUNT ON;
    INSERT INTO dbo.users (email, username, hashed_password, full_name, role, is_active, created_at)
    OUTPUT INSERTED.id AS UserId
    VALUES (@Email, @Username, @HashedPassword, @FullName, @Role, 1, SYSUTCDATETIME());
END
GO

-- Update user
IF OBJECT_ID('dbo.sp_UpdateUser','P') IS NOT NULL DROP PROCEDURE dbo.sp_UpdateUser;
GO
CREATE PROCEDURE dbo.sp_UpdateUser
    @UserId INT,
    @Email NVARCHAR(255) = NULL,
    @Username NVARCHAR(50) = NULL,
    @FullName NVARCHAR(100) = NULL,
    @Role NVARCHAR(20) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    UPDATE dbo.users
    SET email = ISNULL(@Email, email),
        username = ISNULL(@Username, username),
        full_name = ISNULL(@FullName, full_name),
        role = ISNULL(@Role, role),
        updated_at = SYSUTCDATETIME()
    WHERE id = @UserId;
    SELECT @@ROWCOUNT AS AffectedRows;
END
GO

-- Set user password (hashed)
IF OBJECT_ID('dbo.sp_SetUserPasswordHashed','P') IS NOT NULL DROP PROCEDURE dbo.sp_SetUserPasswordHashed;
GO
CREATE PROCEDURE dbo.sp_SetUserPasswordHashed
    @UserId INT,
    @HashedPassword NVARCHAR(255)
AS
BEGIN
    SET NOCOUNT ON;
    UPDATE dbo.users
    SET hashed_password = @HashedPassword,
        updated_at = SYSUTCDATETIME()
    WHERE id = @UserId;
    SELECT @@ROWCOUNT AS AffectedRows;
END
GO

-- Owner profile shell
IF OBJECT_ID('dbo.sp_CreateOwnerProfile','P') IS NOT NULL DROP PROCEDURE dbo.sp_CreateOwnerProfile;
GO
CREATE PROCEDURE dbo.sp_CreateOwnerProfile
    @UserId INT,
    @Phone NVARCHAR(50) = NULL,
    @Address NVARCHAR(500) = NULL,
    @Company NVARCHAR(200) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    IF EXISTS (SELECT 1 FROM dbo.owner_profiles WHERE user_id = @UserId)
    BEGIN
        UPDATE dbo.owner_profiles
        SET contact_number = ISNULL(@Phone, contact_number),
            address = ISNULL(@Address, address),
            company_name = ISNULL(@Company, company_name),
            updated_at = SYSUTCDATETIME()
        WHERE user_id = @UserId;
        SELECT @@ROWCOUNT AS AffectedRows;
        RETURN;
    END
    INSERT INTO dbo.owner_profiles (user_id, company_name, contact_number, address, created_at)
    OUTPUT INSERTED.id AS ProfileId
    VALUES (@UserId, @Company, @Phone, @Address, SYSUTCDATETIME());
END
GO

-- Renter profile shell
IF OBJECT_ID('dbo.sp_CreateRenterProfile','P') IS NOT NULL DROP PROCEDURE dbo.sp_CreateRenterProfile;
GO
CREATE PROCEDURE dbo.sp_CreateRenterProfile
    @UserId INT,
    @Phone NVARCHAR(50) = NULL,
    @Address NVARCHAR(500) = NULL,
    @LeaseStart DATE = NULL,
    @LeaseEnd DATE = NULL
AS
BEGIN
    SET NOCOUNT ON;
    IF EXISTS (SELECT 1 FROM dbo.renter_profiles WHERE user_id = @UserId)
    BEGIN
        UPDATE dbo.renter_profiles
        SET phone_number = ISNULL(@Phone, phone_number),
            current_address = ISNULL(@Address, current_address),
            updated_at = SYSUTCDATETIME()
        WHERE user_id = @UserId;
        SELECT @@ROWCOUNT AS AffectedRows;
        RETURN;
    END
    INSERT INTO dbo.renter_profiles (user_id, phone_number, current_address, created_at)
    OUTPUT INSERTED.id AS ProfileId
    VALUES (@UserId, @Phone, @Address, SYSUTCDATETIME());
END
GO
