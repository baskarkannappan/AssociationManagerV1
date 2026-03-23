CREATE   PROCEDURE assoc.sp_TariffLayers_Delete @LayerId INT AS 
BEGIN DELETE FROM assoc.TariffLayers WHERE TariffLayerId = @LayerId; END