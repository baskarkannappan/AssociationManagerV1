CREATE   PROCEDURE corp.sp_UserAssociations_Delete @UserId INT, @TenantId INT AS 
BEGIN DELETE FROM corp.UserAssociations WHERE UserId = @UserId AND TenantId = @TenantId; END