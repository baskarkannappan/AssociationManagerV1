-- ASSET TARIFFS
CREATE   PROCEDURE assoc.sp_AssetTariffs_GetByAssetId @AssetId INT AS 
BEGIN SELECT * FROM assoc.AssetTariffs WHERE AssetId = @AssetId; END