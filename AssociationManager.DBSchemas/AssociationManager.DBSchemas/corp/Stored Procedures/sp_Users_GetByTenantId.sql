CREATE   PROCEDURE corp.sp_Users_GetByTenantId @TenantId INT AS 
BEGIN SELECT u.*, ua.Role FROM corp.Users u JOIN corp.UserAssociations ua ON u.UserId = ua.UserId WHERE ua.TenantId = @TenantId; END