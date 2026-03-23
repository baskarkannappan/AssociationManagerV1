CREATE   PROCEDURE assoc.sp_AssetTariffs_Delete @AssetId INT, @LayerId INT AS 
BEGIN DELETE FROM assoc.AssetTariffs WHERE AssetId = @AssetId AND TariffLayerId = @LayerId; END