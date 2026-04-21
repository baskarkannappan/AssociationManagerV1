CREATE OR ALTER PROCEDURE assoc.sp_Finance_GetAssociationSummary
    @AssociationId INT,
    @TenantId INT,
    @TotalOutstanding_OUT DECIMAL(18,2) = NULL OUTPUT,
    @TotalAdvanceCredits_OUT DECIMAL(18,2) = NULL OUTPUT,
    @UnitsWithCredit_OUT INT = NULL OUTPUT
AS
BEGIN
    SET NOCOUNT ON;

    -- Enhanced NetDue Calculation (Dynamic Fines + Partial Payments)
    DECLARE @StrategyType NVARCHAR(50), @FineValue DECIMAL(18,2), @GracePeriodDays INT, @IsCompounding BIT, @ActivationDate DATETIME;
    
    SELECT TOP 1 @StrategyType = StrategyType, @FineValue = FineValue, @GracePeriodDays = GracePeriodDays, @IsCompounding = IsCompounding, @ActivationDate = ActivationDate
    FROM assoc.FineSettings WHERE AssociationId = @AssociationId AND TenantId = @TenantId;

    WITH InvoiceData AS (
        SELECT 
            i.InvoiceId, i.DueDate, i.CreatedDate, i.Amount, i.[Status],
            ISNULL(fines.TotalFines, 0) as RecordedFines,
            ISNULL(payments.TotalPaid, 0) as TotalPaid
        FROM assoc.Invoices i WITH (NOLOCK)
        OUTER APPLY (
            SELECT SUM(li.Amount) as TotalFines FROM assoc.InvoiceLineItems li WITH (NOLOCK)
            WHERE li.InvoiceId = i.InvoiceId AND (li.ChargeName LIKE '%Penalty%' OR li.ChargeName LIKE '%Fine%')
        ) fines
        OUTER APPLY (
            SELECT SUM(p.Amount) as TotalPaid FROM assoc.Payments p WITH (NOLOCK)
            WHERE p.InvoiceId = i.InvoiceId AND p.Status IN ('Paid', 'Completed', 'Captured')
        ) payments
        WHERE i.TenantId = @TenantId AND i.AssociationId = @AssociationId
        AND i.[Status] NOT IN ('Paid', 'Cancelled', 'Void', 'Draft')
    ),
    CalculatedFines AS (
        SELECT 
            d.*,
            CASE 
                WHEN d.DueDate >= GETUTCDATE() THEN 0
                WHEN @StrategyType IS NULL OR @StrategyType = 'None' THEN 0
                WHEN @ActivationDate IS NULL OR d.CreatedDate < @ActivationDate THEN 0
                WHEN DATEDIFF(DAY, d.DueDate, GETUTCDATE()) <= @GracePeriodDays THEN 0
                WHEN d.RecordedFines > 0 THEN 0 
                ELSE 
                    (SELECT 
                        CASE 
                            WHEN @StrategyType = 'FlatAmount' THEN @FineValue * monthsLate
                            WHEN @StrategyType = 'OneTimeFlat' THEN @FineValue
                            WHEN @StrategyType = 'OneTimePercentage' THEN ROUND(d.Amount * (@FineValue / 100.0), 2)
                            WHEN @StrategyType = 'Percentage' AND @IsCompounding = 0 THEN ROUND(d.Amount * (@FineValue / 100.0) * monthsLate, 2)
                            WHEN @StrategyType = 'Percentage' AND @IsCompounding = 1 THEN ROUND(d.Amount * (POWER(CAST(1 + (@FineValue / 100.0) AS FLOAT), monthsLate)) - d.Amount, 2)
                            ELSE 0
                        END
                     FROM (SELECT CEILING(DATEDIFF(DAY, d.DueDate, GETUTCDATE()) / 30.44) as monthsLate) m
                    )
            END as DynamicFine
        FROM InvoiceData d
    )
    SELECT @TotalOutstanding = ISNULL(SUM(CAST((Amount + RecordedFines + DynamicFine) - TotalPaid AS DECIMAL(18,2))), 0)
    FROM CalculatedFines
    WHERE (Amount + RecordedFines + DynamicFine) - TotalPaid > 0;

    -- 2. Optimized Wallet Balances
    DECLARE @TotalAdvanceCredits DECIMAL(18,2) = 0;
    DECLARE @UnitsWithCredit INT = 0;

    WITH WalletBalances AS (
        SELECT 
            AssetId,
            SUM(CASE WHEN Type = 'Credit' AND (Category = 'Payment' OR Category = 'Advance Payment') AND (InvoiceId IS NULL OR InvoiceId = 0) THEN Amount ELSE 0 END) -
            SUM(CASE WHEN Type = 'Debit' AND (Category = 'Credit Settlement' OR Category = 'Internal Credit Transfer') THEN Amount ELSE 0 END) as Balance
        FROM assoc.Transactions WITH (NOLOCK)
        WHERE TenantId = @TenantId AND AssociationId = @AssociationId
        GROUP BY AssetId
    )
    SELECT 
        @TotalAdvanceCredits = ISNULL(SUM(Balance), 0),
        @UnitsWithCredit = COUNT(*)
    FROM WalletBalances
    WHERE Balance > 0;

    -- Set Output Parameters
    IF @TotalOutstanding_OUT IS NOT NULL SET @TotalOutstanding_OUT = @TotalOutstanding;
    IF @TotalAdvanceCredits_OUT IS NOT NULL SET @TotalAdvanceCredits_OUT = @TotalAdvanceCredits;
    IF @UnitsWithCredit_OUT IS NOT NULL SET @UnitsWithCredit_OUT = @UnitsWithCredit;
    
    -- API result fallback assignment
    SET @TotalOutstanding_OUT = @TotalOutstanding;
    SET @TotalAdvanceCredits_OUT = @TotalAdvanceCredits;
    SET @UnitsWithCredit_OUT = @UnitsWithCredit;

    -- 3. Return results
    SELECT 
        CAST(ISNULL(@TotalOutstanding, 0) AS DECIMAL(18,2)) as TotalOutstanding, 
        CAST(ISNULL(@TotalAdvanceCredits, 0) AS DECIMAL(18,2)) as TotalAdvanceCredits, 
        ISNULL(@UnitsWithCredit, 0) as UnitsWithCredit;
END
GO