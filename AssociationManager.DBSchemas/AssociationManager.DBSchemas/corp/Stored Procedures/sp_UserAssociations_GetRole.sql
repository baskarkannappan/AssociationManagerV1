
-- 7. Get Role for Context (Schema-aware)
CREATE   PROCEDURE corp.sp_UserAssociations_GetRole
    @UserId INT,
    @TenantId INT
AS
BEGIN
    -- 1. Check direct tenant mapping
    DECLARE @Role NVARCHAR(50) = (SELECT TOP 1 Role FROM corp.UserAssociations WHERE UserId = @UserId AND TenantId = @TenantId);
    
    IF @Role IS NOT NULL
        SELECT @Role;
    ELSE
    BEGIN
        -- 2. Check if user is global admin in corp.Users
        SELECT Role FROM corp.Users WHERE UserId = @UserId AND Role IN ('SystemAdmin', 'PlatformAdmin');
    END
END;