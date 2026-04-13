CREATE OR ALTER PROCEDURE assoc.sp_Finance_GetAssociationSummary
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

    -- 1. Calculate Total Outstanding (JOIN with Line Items to include Penalties)
    DECLARE @TotalOutstanding DECIMAL(18,2) = 0;
    
    SELECT @TotalOutstanding = ISNULL(SUM(
        CASE 
            WHEN lt.LineCount = 0 THEN i.Amount
            ELSE (CASE WHEN i.Amount > lt.PrincipalLineSum THEN i.Amount ELSE lt.PrincipalLineSum END) + lt.PenaltyLineSum
        END
    ), 0)
    FROM assoc.Invoices i
    OUTER APPLY (
        SELECT 
            COUNT(*) as LineCount,
            ISNULL(SUM(CASE WHEN li.ChargeName NOT LIKE '%Penalty%' AND li.ChargeName NOT LIKE '%Fine%' THEN li.Amount ELSE 0 END), 0) as PrincipalLineSum,
            ISNULL(SUM(CASE WHEN li.ChargeName LIKE '%Penalty%' OR li.ChargeName LIKE '%Fine%' THEN li.Amount ELSE 0 END), 0) as PenaltyLineSum
        FROM assoc.InvoiceLineItems li
        WHERE li.InvoiceId = i.InvoiceId
    ) lt
    WHERE i.TenantId = @TenantId AND i.AssociationId = @AssociationId
    AND i.Status NOT IN ('Paid', 'Cancelled', 'Void', 'Draft');

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