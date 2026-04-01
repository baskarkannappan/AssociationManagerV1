-- 2. Fix Balance Calculation (Debit vs Credit) in Admin Summary
CREATE   PROCEDURE assoc.sp_Finance_GetAssociationSummary
    @AssociationId INT,
    @TenantId INT
 AS
 BEGIN
     SET NOCOUNT ON;
 
     DECLARE @TotalOutstanding DECIMAL(18,2);
     DECLARE @TotalAdvanceCredits DECIMAL(18,2);
     DECLARE @UnitBalances TABLE (AssetId INT, Balance DECIMAL(18,2));
 
     INSERT INTO @UnitBalances (AssetId, Balance)
     SELECT AssetId, SUM(CASE WHEN Type = 'Debit' THEN Amount ELSE -Amount END) -- FIX: Signed Sum
     FROM assoc.Transactions
     WHERE TenantId = @TenantId AND AssociationId = @AssociationId
     GROUP BY AssetId;
 
     SELECT @TotalOutstanding = ISNULL(SUM(Balance), 0) FROM @UnitBalances WHERE Balance > 0;
     SELECT @TotalAdvanceCredits = ABS(ISNULL(SUM(Balance), 0)) FROM @UnitBalances WHERE Balance < 0;
 
     SELECT 
         @TotalOutstanding as TotalOutstanding,
         @TotalAdvanceCredits as TotalAdvanceCredits,
         (SELECT COUNT(*) FROM @UnitBalances WHERE Balance < 0) as UnitsWithCredit;
 END;