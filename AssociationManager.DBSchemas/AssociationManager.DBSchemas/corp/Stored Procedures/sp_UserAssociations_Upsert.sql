CREATE   PROCEDURE corp.sp_UserAssociations_Upsert @UserId INT, @TenantId INT, @Role NVARCHAR(50) AS 
BEGIN 
    IF EXISTS (SELECT 1 FROM corp.UserAssociations WHERE UserId = @UserId AND TenantId = @TenantId)
        UPDATE corp.UserAssociations SET Role = @Role WHERE UserId = @UserId AND TenantId = @TenantId
    ELSE
        INSERT INTO corp.UserAssociations (UserId, TenantId, Role) VALUES (@UserId, @TenantId, @Role);
END