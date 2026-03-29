CREATE   PROCEDURE assoc.sp_Transactions_GetBalanceByAssetId @AssetId INT, @TenantId INT, @AssociationId INT AS 
BEGIN 
    SELECT ISNULL(SUM(CASE WHEN Type = 'Credit' THEN Amount ELSE -Amount END), 0) 
    FROM assoc.Transactions 
    WHERE AssetId = @AssetId AND AssociationId = @AssociationId; 
END