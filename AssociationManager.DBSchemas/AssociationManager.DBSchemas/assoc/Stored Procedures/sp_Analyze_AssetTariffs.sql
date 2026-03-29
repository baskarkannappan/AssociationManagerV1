-- 1. Analyze Asset Tariffs
CREATE   PROCEDURE assoc.sp_Analyze_AssetTariffs
    @AssociationId INT = NULL,
    @AssetId INT = NULL
AS
BEGIN
    SELECT 
        a.AssetId,
        a.Name AS AssetName,
        a.AssetType,
        tl.Name AS TariffName,
        tl.BaseRate,
        at.CustomAmount,
        at.IsActive,
        at.IsRecurring,
        tg.Name AS GroupName
    FROM assoc.Assets a
    JOIN assoc.AssetTariffs at ON a.AssetId = at.AssetId
    JOIN assoc.TariffLayers tl ON at.TariffLayerId = tl.TariffLayerId
    JOIN assoc.TariffGroups tg ON tl.TariffGroupId = tg.TariffGroupId
    WHERE (@AssociationId IS NULL OR a.AssociationId = @AssociationId)
      AND (@AssetId IS NULL OR a.AssetId = @AssetId)
    ORDER BY a.Name, tg.Name, tl.Name;
END