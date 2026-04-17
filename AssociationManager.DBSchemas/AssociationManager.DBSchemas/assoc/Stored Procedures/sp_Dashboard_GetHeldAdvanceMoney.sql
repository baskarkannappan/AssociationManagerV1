CREATE   PROCEDURE assoc.sp_Dashboard_GetHeldAdvanceMoney
    @TenantId INT,
    @AssociationId INT,
    @TotalAdvanceCredits_OUT DECIMAL(18,2) = NULL OUTPUT,
    @UnitsWithCredit_OUT INT = NULL OUTPUT
AS
/*
    LOGIC RULE: Held Advance Money Calculation (Dashboard Optimized)
    ----------------------------------------------------------------
    Calculates unassigned (spendable) advance pool as per the Ledger Standard.
    Matches the 'Wallet' balance shown to residents.
*/
BEGIN
    SET NOCOUNT ON;

    DECLARE @TotalAdvanceCredits DECIMAL(18,2) = 0;
    DECLARE @UnitsWithCredit INT = 0;

    WITH WalletBalances AS (
        SELECT 
            AssetId,
            SUM(CASE WHEN Type = 'Credit' AND (Category = 'Payment' OR Category = 'Advance Payment') AND (InvoiceId IS NULL OR InvoiceId = 0) THEN Amount ELSE 0 END) -
            SUM(CASE WHEN Type = 'Debit' AND (Category = 'Credit Settlement' OR Category = 'Internal Credit Transfer') THEN Amount ELSE 0 END) as Balance
        FROM assoc.Transactions
        WHERE TenantId = @TenantId AND AssociationId = @AssociationId
        GROUP BY AssetId
    )
    SELECT 
        @TotalAdvanceCredits = CAST(ISNULL(SUM(Balance), 0) AS DECIMAL(18,2)),
        @UnitsWithCredit = CAST(COUNT(CASE WHEN Balance > 0 THEN 1 END) AS INT)
    FROM WalletBalances
    WHERE Balance > 0;

    -- Set Output Parameters for inter-procedure 
    IF @TotalAdvanceCredits_OUT IS NOT NULL SET @TotalAdvanceCredits_OUT = @TotalAdvanceCredits;
    IF @UnitsWithCredit_OUT IS NOT NULL SET @UnitsWithCredit_OUT = @UnitsWithCredit;

    -- CRITICAL: Only return a result set if called directly by the application (@@NESTLEVEL = 1)
    -- This prevents polluting the result set of other procedures (like Revenue).
    IF @@NESTLEVEL = 1
    BEGIN
        SELECT @TotalAdvanceCredits as TotalAdvanceCredits, @UnitsWithCredit as UnitsWithCredit;
    END
END