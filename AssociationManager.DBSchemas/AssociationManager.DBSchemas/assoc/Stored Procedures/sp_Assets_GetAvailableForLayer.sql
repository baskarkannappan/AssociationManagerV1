CREATE PROCEDURE [assoc].[sp_Assets_GetAvailableForLayer]
    @AssociationId INT,
    @LayerId INT
AS
BEGIN
    SET NOCOUNT ON;

    -- Get only assets from this association that are NOT already assigned to this specific layer
    SELECT a.*
    FROM assoc.Assets a
    LEFT JOIN assoc.AssetTariffs at ON a.AssetId = at.AssetId AND at.TariffLayerId = @LayerId
    WHERE a.AssociationId = @AssociationId 
      AND a.IsActive = 1
      AND (at.AssetId IS NULL OR at.IsActive = 0) -- Either not assigned, or was deactivated
    ORDER BY a.Name;
END
