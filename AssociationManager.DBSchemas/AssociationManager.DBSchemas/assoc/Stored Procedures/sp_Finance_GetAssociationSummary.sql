
CREATE   PROCEDURE assoc.sp_Finance_GetAssociationSummary
    @AssociationId INT,
    @TenantId INT
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @UnitBalances TABLE (AssetId INT, Balance DECIMAL(18,2));

    -- Sum all transactions per asset to get current net position
    -- Debit (+) = Owed, Credit (-) = Paid/Advance
    INSERT INTO @UnitBalances (AssetId, Balance)
    SELECT AssetId, ISNULL(SUM(CASE WHEN Type = 'Debit' THEN Amount ELSE -Amount END), 0)
    FROM assoc.Transactions
    WHERE TenantId = @TenantId AND AssociationId = @AssociationId
    AND Category != 'Credit Settlement'
    GROUP BY AssetId;

    -- Total Outstanding is the sum of all units that currently owe money
    DECLARE @TotalOutstanding DECIMAL(18,2) = (SELECT ISNULL(SUM(Balance), 0) FROM @UnitBalances WHERE Balance > 0);
    
    -- Total Advance is the sum of all units that have overpaid (absolute value)
    DECLARE @TotalAdvanceCredits DECIMAL(18,2) = (SELECT ABS(ISNULL(SUM(Balance), 0)) FROM @UnitBalances WHERE Balance < 0);
    
    -- Count of units currently in credit
    DECLARE @UnitsWithCredit INT = (SELECT COUNT(*) FROM @UnitBalances WHERE Balance < 0);

    SELECT 
        @TotalOutstanding as TotalOutstanding,
        @TotalAdvanceCredits as TotalAdvanceCredits,
        @UnitsWithCredit as UnitsWithCredit;
END