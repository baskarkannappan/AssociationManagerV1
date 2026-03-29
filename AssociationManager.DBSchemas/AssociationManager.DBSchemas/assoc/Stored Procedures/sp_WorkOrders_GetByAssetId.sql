CREATE   PROCEDURE assoc.sp_WorkOrders_GetByAssetId @AssetId INT, @TenantId INT, @AssociationId INT AS 
BEGIN 
    SELECT w.*, a.Name as AssetName 
    FROM assoc.WorkOrders w 
    LEFT JOIN assoc.Assets a ON w.AssetId = a.AssetId 
    WHERE w.AssetId = @AssetId AND w.AssociationId = @AssociationId 
    ORDER BY w.CreatedDate DESC; 
END