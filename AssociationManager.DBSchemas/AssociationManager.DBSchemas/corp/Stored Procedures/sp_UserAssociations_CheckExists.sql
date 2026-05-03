
CREATE   PROCEDURE corp.sp_UserAssociations_CheckExists @UserId INT, @TenantId INT AS 
BEGIN SELECT COUNT(1) FROM corp.UserAssociations WHERE UserId = @UserId AND TenantId = @TenantId; END