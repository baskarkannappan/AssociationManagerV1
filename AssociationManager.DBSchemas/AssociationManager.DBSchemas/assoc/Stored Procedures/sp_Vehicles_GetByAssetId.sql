-- VEHICLES
CREATE   PROCEDURE assoc.sp_Vehicles_GetByAssetId @AssetId INT, @TenantId INT, @AssociationId INT AS 
BEGIN SELECT * FROM assoc.Vehicles WHERE AssetId = @AssetId AND AssociationId = @AssociationId; END
GO