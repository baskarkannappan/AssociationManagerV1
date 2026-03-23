CREATE   PROCEDURE assoc.sp_Pets_Delete @Id INT, @TenantId INT, @AssociationId INT AS 
BEGIN DELETE FROM assoc.Pets WHERE PetId = @Id AND TenantId = @TenantId AND AssociationId = @AssociationId; END