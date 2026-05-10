CREATE PROCEDURE assoc.sp_AssetTariffs_GetActiveByAssociationId
    @AssociationId INT,
    @TenantId INT
AS
BEGIN
    SET NOCOUNT ON;
    
    SELECT at.*, tl.Name AS ChargeName
    FROM assoc.AssetTariffs at
    INNER JOIN assoc.TariffLayers tl ON at.TariffLayerId = tl.TariffLayerId
    WHERE tl.AssociationId = @AssociationId 
      AND tl.TenantId = @TenantId 
      AND at.IsActive = 1;
END
GO
