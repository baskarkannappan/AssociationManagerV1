CREATE   PROCEDURE assoc.sp_Invoices_GetByAssetId @AssetId INT, @TenantId INT, @AssociationId INT AS 
BEGIN 
    SELECT i.*, a.Name as AssetName 
    FROM assoc.Invoices i 
    LEFT JOIN assoc.Assets a ON i.AssetId = a.AssetId 
    WHERE i.AssetId = @AssetId AND i.AssociationId = @AssociationId 
    ORDER BY i.DueDate DESC; 
END