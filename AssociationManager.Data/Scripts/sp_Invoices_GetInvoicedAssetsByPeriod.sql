CREATE OR ALTER PROCEDURE assoc.sp_Invoices_GetInvoicedAssetsByPeriod
    @TenantId INT,
    @AssociationId INT,
    @PeriodPattern NVARCHAR(200)
AS
BEGIN
    SET NOCOUNT ON;

    -- Lightweight query for billing duplicate detection.
    -- Returns only the AssetIds that already have invoices matching the given period pattern.
    -- This avoids loading full invoice + line item data which causes timeouts on large datasets.
    SELECT AssetId
    FROM assoc.Invoices
    WHERE TenantId = @TenantId
      AND AssociationId = @AssociationId
      AND Title LIKE @PeriodPattern
      AND AssetId IS NOT NULL;
END
