CREATE PROCEDURE assoc.sp_AssetTariffs_GetByAssetId
    @AssetId INT
AS
BEGIN
    SELECT at.*, tl.Name AS ChargeName
    FROM assoc.AssetTariffs at
    JOIN assoc.TariffLayers tl ON at.TariffLayerId = tl.TariffLayerId
    WHERE at.AssetId = @AssetId;
END