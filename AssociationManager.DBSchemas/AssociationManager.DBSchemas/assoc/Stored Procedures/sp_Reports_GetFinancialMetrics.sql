CREATE OR ALTER PROCEDURE assoc.sp_Reports_GetFinancialMetrics
    @TenantId INT,
    @AssociationId INT
AS
BEGIN
    SET NOCOUNT ON;

    -- Local variables for Fine Settings
    DECLARE @StrategyType NVARCHAR(50), @FineValue DECIMAL(18,2), @GracePeriodDays INT, @IsCompounding BIT, @ActivationDate DATETIME;
    
    SELECT TOP 1 
        @StrategyType = StrategyType,
        @FineValue = FineValue,
        @GracePeriodDays = GracePeriodDays,
        @IsCompounding = IsCompounding,
        @ActivationDate = ActivationDate
    FROM assoc.FineSettings
    WHERE AssociationId = @AssociationId AND TenantId = @TenantId;

    -- 1. Pre-calculate metrics in Bulk (Much faster than OUTER APPLY)
    WITH FineAgg AS (
        SELECT li.InvoiceId, SUM(li.Amount) as TotalFines
        FROM assoc.InvoiceLineItems li
        JOIN assoc.Invoices i ON li.InvoiceId = i.InvoiceId
        WHERE i.TenantId = @TenantId AND i.AssociationId = @AssociationId
        AND (li.ChargeName LIKE '%Penalty%' OR li.ChargeName LIKE '%Fine%')
        GROUP BY li.InvoiceId
    ),
    PaymentAgg AS (
        SELECT p.InvoiceId, SUM(p.Amount) as TotalPaid
        FROM assoc.Payments p
        WHERE p.TenantId = @TenantId AND p.AssociationId = @AssociationId
        AND p.Status IN ('Paid', 'Completed', 'Captured')
        GROUP BY p.InvoiceId
    ),
    InvoiceData AS (
        SELECT 
            i.InvoiceId,
            i.DueDate,
            i.CreatedDate,
            i.Amount,
            i.[Status],
            ISNULL(f.TotalFines, 0) as RecordedFines,
            ISNULL(p.TotalPaid, 0) as TotalPaid
        FROM assoc.Invoices i
        LEFT JOIN FineAgg f ON i.InvoiceId = f.InvoiceId
        LEFT JOIN PaymentAgg p ON i.InvoiceId = p.InvoiceId
        WHERE i.TenantId = @TenantId AND i.AssociationId = @AssociationId
        AND i.[Status] NOT IN ('Cancelled', 'Void', 'Draft')
    ),
    CalculatedFines AS (
        SELECT 
            d.*,
            -- Pre-calculate commonly used values for efficiency
            CEILING(DATEDIFF(DAY, d.DueDate, GETUTCDATE()) / 30.44) as monthsLate,
            CASE 
                WHEN d.[Status] = 'Paid' OR d.DueDate >= GETUTCDATE() OR @StrategyType IS NULL OR @StrategyType = 'None' OR @ActivationDate IS NULL OR d.CreatedDate < @ActivationDate OR DATEDIFF(DAY, d.DueDate, GETUTCDATE()) <= @GracePeriodDays 
                THEN 0 ELSE 1 
            END as AppliesFine
        FROM InvoiceData d
    ),
    DynamicFineCalc AS (
        SELECT 
            f.*,
            CASE 
                WHEN f.AppliesFine = 0 THEN 0
                ELSE
                    -- Inline fine calculation logic to avoid correlated subqueries
                    CASE 
                        WHEN @StrategyType = 'FlatAmount' THEN @FineValue * f.monthsLate
                        WHEN @StrategyType = 'OneTimeFlat' THEN @FineValue
                        WHEN @StrategyType = 'OneTimePercentage' THEN ROUND(f.Amount * (@FineValue / 100.0), 2)
                        WHEN @StrategyType = 'Percentage' AND @IsCompounding = 0 THEN ROUND(f.Amount * (@FineValue / 100.0) * f.monthsLate, 2)
                        WHEN @StrategyType = 'Percentage' AND @IsCompounding = 1 THEN ROUND(f.Amount * (POWER(CAST(1 + (@FineValue / 100.0) AS FLOAT), f.monthsLate)) - f.Amount, 2)
                        ELSE 0
                    END
            END as RawDynamicFine
        FROM CalculatedFines f
    ),
    FinalFines AS (
        SELECT 
            f.*,
            CASE 
                WHEN f.RawDynamicFine - f.RecordedFines > 0 THEN CAST(f.RawDynamicFine - f.RecordedFines AS DECIMAL(18,2))
                ELSE 0
            END as DynamicFine
        FROM DynamicFineCalc f
    ),
    NetInvoiceStats AS (
        SELECT 
            *,
            -- Explicitly cast to DECIMAL to avoid float issues from POWER function
            CAST((Amount + RecordedFines + DynamicFine) - TotalPaid AS DECIMAL(18,2)) as NetDue,
            CAST(Amount + RecordedFines + DynamicFine AS DECIMAL(18,2)) as GrossBilled
        FROM FinalFines
    )
    SELECT * INTO #NetInvoiceStats FROM NetInvoiceStats;

    -- 2. Aging Calculation
    SELECT 
        ISNULL(SUM(CASE WHEN DATEDIFF(day, DueDate, GETUTCDATE()) BETWEEN 0 AND 30 AND NetDue > 0 THEN NetDue ELSE 0 END), 0) AS Bucket0_30,
        ISNULL(SUM(CASE WHEN DATEDIFF(day, DueDate, GETUTCDATE()) BETWEEN 31 AND 60 AND NetDue > 0 THEN NetDue ELSE 0 END), 0) AS Bucket31_60,
        ISNULL(SUM(CASE WHEN DATEDIFF(day, DueDate, GETUTCDATE()) BETWEEN 61 AND 90 AND NetDue > 0 THEN NetDue ELSE 0 END), 0) AS Bucket61_90,
        ISNULL(SUM(CASE WHEN DATEDIFF(day, DueDate, GETUTCDATE()) > 90 AND NetDue > 0 THEN NetDue ELSE 0 END), 0) AS BucketOver90
    FROM #NetInvoiceStats;

    -- 3. Monthly Collection Efficiency
    WITH Months AS (
        SELECT TOP 12 
            FORMAT(DATEADD(MONTH, - (ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) - 1), GETUTCDATE()), 'MMM yyyy') AS MonthLabel,
            DATEPART(MONTH, DATEADD(MONTH, - (ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) - 1), GETUTCDATE())) AS [Month],
            DATEPART(YEAR, DATEADD(MONTH, - (ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) - 1), GETUTCDATE())) AS [Year]
        FROM sys.objects
    ),
    MonthlyStats AS (
        SELECT 
            DATEPART(MONTH, DueDate) as [Month],
            DATEPART(YEAR, DueDate) as [Year],
            SUM(GrossBilled) as TotalBilled,
            SUM(TotalPaid) as TotalCollected
        FROM #NetInvoiceStats
        GROUP BY DATEPART(MONTH, DueDate), DATEPART(YEAR, DueDate)
    )
    SELECT 
        m.MonthLabel as [Month],
        ISNULL(ms.TotalBilled, 0) as BilledAmount,
        ISNULL(ms.TotalCollected, 0) as CollectedAmount
    FROM Months m
    LEFT JOIN MonthlyStats ms ON m.[Month] = ms.[Month] AND m.[Year] = ms.[Year]
    ORDER BY m.[Year] ASC, m.[Month] ASC;

    -- 4. High Level Stats
    SELECT 
        (SELECT ISNULL(SUM(Amount), 0) FROM assoc.Payments WHERE TenantId = @TenantId AND AssociationId = @AssociationId AND Status IN ('Paid', 'Completed', 'Captured')) as TotalCollectedAllTime,
        (SELECT ISNULL(SUM(NetDue), 0) FROM #NetInvoiceStats WHERE NetDue > 0) as TotalUnpaidPrincipal

    DROP TABLE #NetInvoiceStats;
END