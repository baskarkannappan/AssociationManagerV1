CREATE PROCEDURE assoc.sp_AssetTariffs_GetActiveByTenantId
    @TenantId INT
AS
BEGIN
    SELECT at.*, tl.Name AS ChargeName
    FROM assoc.AssetTariffs at
    JOIN assoc.TariffLayers tl ON at.TariffLayerId = tl.TariffLayerId
    WHERE tl.TenantId = @TenantId AND at.IsActive = 1;
END