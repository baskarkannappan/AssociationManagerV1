-- TRANSACTIONS
CREATE   PROCEDURE assoc.sp_Transactions_GetByAssetId @AssetId INT, @TenantId INT, @AssociationId INT AS 
BEGIN 
    SELECT * FROM assoc.Transactions 
    WHERE AssetId = @AssetId AND AssociationId = @AssociationId 
    ORDER BY TransactionDate DESC; 
END