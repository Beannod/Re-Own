-- Add sp_GetAllUsers stored procedure 
IF OBJECT_ID('sp_GetAllUsers', 'P') IS NOT NULL DROP PROCEDURE sp_GetAllUsers;
GO

CREATE PROCEDURE sp_GetAllUsers
    @Role NVARCHAR(20) = NULL,
    @IsActive BIT = NULL,
    @SearchTerm NVARCHAR(255) = NULL
AS
BEGIN
    SET NOCOUNT ON;

    -- Validate role if provided
    IF @Role IS NOT NULL AND @Role NOT IN ('owner', 'renter', 'admin')
    BEGIN
        RAISERROR ('Invalid role filter. Role must be either "owner", "renter", or "admin".', 16, 1);
        RETURN;
    END

    -- Build dynamic query for flexible filtering
    DECLARE @SQL NVARCHAR(MAX);
    SET @SQL = N'
    SELECT 
        u.id, 
        u.email, 
        u.username, 
        u.full_name, 
        u.role, 
        u.is_active, 
        u.created_at, 
        u.updated_at
    FROM users u
    WHERE 1=1';

    IF @Role IS NOT NULL
        SET @SQL = @SQL + N' AND role = @Role';

    IF @IsActive IS NOT NULL
        SET @SQL = @SQL + N' AND is_active = @IsActive';

    IF @SearchTerm IS NOT NULL
        SET @SQL = @SQL + N' AND (
            email LIKE ''%'' + @SearchTerm + ''%'' OR
            username LIKE ''%'' + @SearchTerm + ''%'' OR
            full_name LIKE ''%'' + @SearchTerm + ''%''
        )';

    SET @SQL = @SQL + N' ORDER BY created_at DESC';

    -- Execute the dynamic query with parameters
    DECLARE @Params NVARCHAR(MAX);
    SET @Params = N'@Role NVARCHAR(20), @IsActive BIT, @SearchTerm NVARCHAR(255)';
    
    EXEC sp_executesql @SQL, @Params, @Role, @IsActive, @SearchTerm;
END;
GO