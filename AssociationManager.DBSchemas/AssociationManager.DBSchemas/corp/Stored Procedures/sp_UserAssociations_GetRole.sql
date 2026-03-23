CREATE   PROCEDURE corp.sp_UserAssociations_GetRole @UserId INT, @TenantId INT AS 
BEGIN SELECT Role FROM corp.UserAssociations WHERE UserId = @UserId AND TenantId = @TenantId; END