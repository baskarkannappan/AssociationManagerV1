-- 3. Update sp_Associations_GetAllByTenantId
CREATE   PROCEDURE corp.sp_Associations_GetAllByTenantId @TenantId INT AS 
BEGIN SELECT * FROM corp.Associations WHERE TenantId = @TenantId; END