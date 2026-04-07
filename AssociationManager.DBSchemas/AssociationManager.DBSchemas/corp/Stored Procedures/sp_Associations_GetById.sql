-- 2. Update sp_Associations_GetById
CREATE   PROCEDURE corp.sp_Associations_GetById @Id INT, @TenantId INT AS 
BEGIN SELECT * FROM corp.Associations WHERE AssociationId = @Id AND TenantId = @TenantId; END