-- ASSETS
CREATE   PROCEDURE assoc.sp_Assets_GetById @Id INT, @TenantId INT, @AssociationId INT AS 
BEGIN SELECT * FROM assoc.Assets WHERE AssetId = @Id AND TenantId = @TenantId AND AssociationId = @AssociationId; END