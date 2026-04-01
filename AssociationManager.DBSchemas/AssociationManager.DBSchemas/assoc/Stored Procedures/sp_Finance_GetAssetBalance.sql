-- 1. Helper to get the current Asset Balance (Outstanding vs Credit)
-- If Balance is negative, it means the user has "Credit" (Advance).
CREATE   PROCEDURE assoc.sp_Finance_GetAssetBalance
    @AssetId INT,
    @TenantId INT,
    @AssociationId INT
AS
BEGIN
    SET NOCOUNT ON;
    
    SELECT IsNull(SUM(CASE WHEN Type = 'Debit' THEN Amount ELSE -Amount END), 0) as CurrentBalance
    FROM assoc.Transactions
    WHERE AssetId = @AssetId 
    AND TenantId = @TenantId 
    AND AssociationId = @AssociationId;
END;