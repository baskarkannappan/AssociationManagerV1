-- TENANTS
CREATE   PROCEDURE corp.sp_Tenants_GetById @Id INT AS 
BEGIN SELECT * FROM corp.Tenants WHERE TenantId = @Id; END