-- Script0071_StandardizeFinancialSignConvention.sql
-- Unifies the sign convention across all financial reports and dashboards.
-- Standard Convention: Positive = Outstanding Debt (Debit > Credit), Negative = Advance Credit (Credit > Debit).

-- 1. Fix Transactions Balance (was inverted in Script0049)
CREATE OR ALTER PROCEDURE assoc.sp_Transactions_GetBalanceByAssetId 
    @AssetId INT, 
    @TenantId INT, 
    @AssociationId INT 
AS 
BEGIN 
    SET NOCOUNT ON;
    -- FIX: Debit is Positive (Owed), Credit is Negative (Paid)
    SELECT ISNULL(SUM(CASE WHEN Type = 'Debit' THEN Amount ELSE -Amount END), 0) 
    FROM assoc.Transactions 
    WHERE AssetId = @AssetId AND AssociationId = @AssociationId; 
END
GO

-- 2. Standardize Finance Asset Balance
CREATE OR ALTER PROCEDURE assoc.sp_Finance_GetAssetBalance
    @AssetId INT,
    @TenantId INT,
    @AssociationId INT
AS
BEGIN
    SET NOCOUNT ON;
    -- Same logic as Transactions_GetBalanceByAssetId for consistency
    SELECT ISNULL(SUM(CASE WHEN Type = 'Debit' THEN Amount ELSE -Amount END), 0) as CurrentBalance
    FROM assoc.Transactions
    WHERE AssetId = @AssetId 
    AND TenantId = @TenantId 
    AND AssociationId = @AssociationId;
END;
GO

PRINT 'Financial sign convention standardized to Positive=Debt, Negative=Credit.'
GO
