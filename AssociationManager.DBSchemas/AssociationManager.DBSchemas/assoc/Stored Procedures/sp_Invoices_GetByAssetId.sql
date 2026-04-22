CREATE   PROCEDURE assoc.sp_Invoices_GetByAssetId
    @AssetId INT,
    @TenantId INT,
    @AssociationId INT
AS
BEGIN
    SELECT i.*
    FROM assoc.Invoices i
    WHERE i.AssetId = @AssetId 
      AND i.TenantId = @TenantId 
      AND (@AssociationId IS NULL OR i.AssociationId = @AssociationId)
    ORDER BY i.CreatedDate DESC;
END