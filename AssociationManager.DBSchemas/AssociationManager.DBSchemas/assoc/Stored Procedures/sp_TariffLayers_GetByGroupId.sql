-- TARIFF LAYERS
CREATE   PROCEDURE assoc.sp_TariffLayers_GetByGroupId @GroupId INT AS 
BEGIN SELECT * FROM assoc.TariffLayers WHERE TariffGroupId = @GroupId; END