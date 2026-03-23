-- PERSONS
CREATE   PROCEDURE assoc.sp_Persons_GetById @Id INT, @TenantId INT, @AssociationId INT AS 
BEGIN SELECT * FROM assoc.Persons WHERE PersonId = @Id AND TenantId = @TenantId AND AssociationId = @AssociationId; END