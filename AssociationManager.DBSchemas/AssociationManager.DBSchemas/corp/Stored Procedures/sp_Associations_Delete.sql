CREATE   PROCEDURE corp.sp_Associations_Delete @Id INT, @TenantId INT AS 
BEGIN DELETE FROM corp.Associations WHERE AssociationId = @Id AND TenantId = @TenantId; END