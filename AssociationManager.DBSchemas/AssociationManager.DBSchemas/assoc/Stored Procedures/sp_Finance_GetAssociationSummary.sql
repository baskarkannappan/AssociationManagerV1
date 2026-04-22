CREATE   PROCEDURE assoc.sp_Finance_GetAssociationSummary
    @AssociationId INT,
    @TenantId INT,
    @TotalOutstanding_OUT DECIMAL(18,2) = NULL OUTPUT,
    @TotalAdvanceCredits_OUT DECIMAL(18,2) = NULL OUTPUT,
    @UnitsWithCredit_OUT INT = NULL OUTPUT
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @TotalOutstanding DECIMAL(18,2) = 0;
    
    -- Principal
    SELECT @TotalOutstanding = ISNULL(SUM(Amount), 0)
    FROM assoc.Invoices
    WHERE TenantId = @TenantId AND AssociationId = @AssociationId
    AND Status IN ('Unpaid', 'Partial')
    AND Status NOT IN ('Draft', 'Cancelled', 'Void');

    -- Penalties
    SELECT @TotalOutstanding = @TotalOutstanding + ISNULL(SUM(li.Amount), 0)
    FROM assoc.InvoiceLineItems li
    INNER JOIN assoc.Invoices i ON i.InvoiceId = li.InvoiceId
    WHERE i.TenantId = @TenantId AND i.AssociationId = @AssociationId
    AND i.Status IN ('Unpaid', 'Partial')
    AND (li.ChargeName LIKE '%Penalty%' OR li.ChargeName LIKE '%Fine%');

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
        @UnitsWithCredit = COUNT(*)
    FROM WalletBalances
    WHERE Balance > 0;

    IF @TotalOutstanding_OUT IS NOT NULL SET @TotalOutstanding_OUT = @TotalOutstanding;
    IF @TotalAdvanceCredits_OUT IS NOT NULL SET @TotalAdvanceCredits_OUT = @TotalAdvanceCredits;
    IF @UnitsWithCredit_OUT IS NOT NULL SET @UnitsWithCredit_OUT = @UnitsWithCredit;
    
    SET @TotalOutstanding_OUT = @TotalOutstanding;
    SET @TotalAdvanceCredits_OUT = @TotalAdvanceCredits;
    SET @UnitsWithCredit_OUT = @UnitsWithCredit;

    SELECT 
        CAST(ISNULL(@TotalOutstanding, 0) AS DECIMAL(18,2)) as TotalOutstanding, 
        CAST(ISNULL(@TotalAdvanceCredits, 0) AS DECIMAL(18,2)) as TotalAdvanceCredits, 
        ISNULL(@UnitsWithCredit, 0) as UnitsWithCredit;
END