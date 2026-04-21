CREATE OR ALTER PROCEDURE assoc.sp_Assets_GetAssignedTariffs
    @AssetId INT,
    @TenantId INT,
    @AssociationId INT
AS
BEGIN
    SET NOCOUNT ON;

    SELECT 
        t.TariffLayerId, 
        t.Name as TariffName, 
        t.AccountingCategory as Category, 
        ISNULL(at.CustomAmount, t.BaseRate) as EffectiveAmount, 
        t.BaseRate as BaseAmount, 
        at.IsActive, 
        at.IsRecurring
    FROM assoc.AssetTariffs at
    JOIN assoc.TariffLayers t ON at.TariffLayerId = t.TariffLayerId
    WHERE at.AssetId = @AssetId 
    AND t.TenantId = @TenantId 
    AND t.AssociationId = @AssociationId;
END
GO
