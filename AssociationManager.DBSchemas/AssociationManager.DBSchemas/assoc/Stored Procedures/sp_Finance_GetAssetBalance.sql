-- Unified Finance Procedures and Logic Fixes

-- 1. Correct Asset Balance Calculation
-- Fixes the bug where Credit Settlements (Wallet Drains) were ignored, leading to incorrect balance reporting.
CREATE   PROCEDURE assoc.sp_Finance_GetAssetBalance
    @AssetId INT,
    @TenantId INT,
    @AssociationId INT
AS
BEGIN
    SET NOCOUNT ON;
    
    -- Negative = Credit (Advance Wallet)
    -- Positive = Debit (Outstanding Debt)
    SELECT IsNull(SUM(CASE WHEN Type = 'Debit' THEN Amount ELSE -Amount END), 0) as CurrentBalance
    FROM assoc.Transactions
    WHERE AssetId = @AssetId 
    AND TenantId = @TenantId 
    AND AssociationId = @AssociationId;
    -- Note: We now INCLUDE all categories (especially Credit Settlement) to ensure accurate spending tracking.
END;