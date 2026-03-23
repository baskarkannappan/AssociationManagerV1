-- OCCUPANCY
CREATE   PROCEDURE assoc.sp_Occupancy_GetByAssetId @AssetId INT, @TenantId INT, @AssociationId INT AS 
BEGIN SELECT * FROM assoc.Occupancy WHERE AssetId = @AssetId AND TenantId = @TenantId AND AssociationId = @AssociationId; END