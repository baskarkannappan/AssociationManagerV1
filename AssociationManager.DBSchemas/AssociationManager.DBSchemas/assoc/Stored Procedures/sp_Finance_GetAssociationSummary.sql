CREATE   PROCEDURE assoc.sp_Finance_GetAssociationSummary
    @AssociationId INT,
    @TenantId INT,
    @TotalOutstanding_OUT DECIMAL(18,2) = NULL OUTPUT,
    @TotalAdvanceCredits_OUT DECIMAL(18,2) = NULL OUTPUT,
    @UnitsWithCredit_OUT INT = NULL OUTPUT
AS
/*
    LOGIC RULE: Finance Summary Standard
    -------------------------------------------
    1. Net Outstanding: Sum of principal for all UNPAID/PARTIAL invoices.
       User Formula: 172 (Total) - 52 (Paid/Advance) = 120.
    
    2. Held Advance Credits (Wallet): Spendable unassigned advances across all units.
       Calculation: (Unassigned Payments) - (Credit Settlements).
*/
BEGIN
    SET NOCOUNT ON;

    -- 1. Calculate Total Outstanding (Direct sum of Unpaid Invoices)
    DECLARE @TotalOutstanding DECIMAL(18,2) = 0;
    SELECT @TotalOutstanding = ISNULL(SUM(Amount), 0)
    FROM assoc.Invoices
    WHERE TenantId = @TenantId AND AssociationId = @AssociationId
    AND Status NOT IN ('Paid', 'Cancelled', 'Void', 'Draft');

    -- 2. Calculate Total Advance Money (Spendable Wallet Balance)
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
        @TotalAdvanceCredits = ISNULL(SUM(Balance), 0),
        @UnitsWithCredit = COUNT(DISTINCT CASE WHEN Balance > 0 THEN AssetId END)
    FROM WalletBalances
    WHERE Balance > 0;

    -- Set Output Parameters if requested
    IF @TotalOutstanding_OUT IS NOT NULL SET @TotalOutstanding_OUT = @TotalOutstanding;
    SET @TotalOutstanding_OUT = @TotalOutstanding; -- Ensure assignment
    SET @TotalAdvanceCredits_OUT = @TotalAdvanceCredits;
    SET @UnitsWithCredit_OUT = @UnitsWithCredit;

    -- 3. Return results for API compatibility
    SELECT 
        CAST(ISNULL(@TotalOutstanding, 0) AS DECIMAL(18,2)) as TotalOutstanding, 
        CAST(ISNULL(@TotalAdvanceCredits, 0) AS DECIMAL(18,2)) as TotalAdvanceCredits, 
        ISNULL(@UnitsWithCredit, 0) as UnitsWithCredit;
END