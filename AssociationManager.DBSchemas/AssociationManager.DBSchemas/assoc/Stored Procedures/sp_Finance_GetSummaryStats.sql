CREATE OR ALTER PROCEDURE assoc.sp_Finance_GetSummaryStats
    @TenantId INT,
    @AssociationId INT,
    @AssetId INT = NULL,
    @AssetIds NVARCHAR(MAX) = NULL
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @TotalUnpaid DECIMAL(18,2) = 0;
    DECLARE @Collected30Days DECIMAL(18,2) = 0;

    -- Enhanced NetDue Calculation (Dynamic Fines + Partial Payments)
    DECLARE @StrategyType NVARCHAR(50), @FineValue DECIMAL(18,2), @GracePeriodDays INT, @IsCompounding BIT, @ActivationDate DATETIME;
    
    SELECT TOP 1 @StrategyType = StrategyType, @FineValue = FineValue, @GracePeriodDays = GracePeriodDays, @IsCompounding = IsCompounding, @ActivationDate = ActivationDate
    FROM assoc.FineSettings WHERE AssociationId = @AssociationId AND TenantId = @TenantId;

    WITH InvoiceData AS (
        SELECT 
            i.InvoiceId, i.DueDate, i.CreatedDate, i.Amount, i.[Status], i.AssetId,
            ISNULL(items.TotalLineItems, 0) as TotalLineItems,
            ISNULL(items.PenaltyLineItems, 0) as PenaltyLineItems,
            ISNULL(payments.TotalPaid, 0) as TotalPaid,
            -- Prioritize Invoice-level fine rules (Rule Snapshot)
            COALESCE(i.FineStrategy, @StrategyType) as EffectiveStrategy,
            COALESCE(i.FineValue, @FineValue) as EffectiveValue,
            COALESCE(i.FineGracePeriod, @GracePeriodDays) as EffectiveGrace,
            COALESCE(i.FineIsCompounding, @IsCompounding) as EffectiveCompounding
        FROM assoc.Invoices i WITH (NOLOCK)
        OUTER APPLY (
            SELECT 
                SUM(li.Amount) as TotalLineItems,
                SUM(CASE WHEN li.ChargeName LIKE '%Penalty%' OR li.ChargeName LIKE '%Fine%' OR li.ChargeName LIKE '%Late%' OR li.ChargeName LIKE '%Interest%' THEN li.Amount ELSE 0 END) as PenaltyLineItems
            FROM assoc.InvoiceLineItems li WITH (NOLOCK)
            WHERE li.InvoiceId = i.InvoiceId 
        ) items
        OUTER APPLY (
            SELECT SUM(p.Amount) as TotalPaid FROM assoc.Payments p WITH (NOLOCK)
            WHERE p.InvoiceId = i.InvoiceId AND p.Status IN ('Paid', 'Completed', 'Captured')
        ) payments
        WHERE i.TenantId = @TenantId AND i.AssociationId = @AssociationId
        AND i.[Status] NOT IN ('Paid', 'Cancelled', 'Void', 'Draft')
        AND (@AssetId IS NULL OR i.AssetId = @AssetId)
        AND (@AssetIds IS NULL OR i.AssetId IN (SELECT CAST(value AS INT) FROM STRING_SPLIT(@AssetIds, ',')))
    ),
    CalculatedFines AS (
        SELECT 
            d.*,
            -- Robust Base Amount: MAX of the recorded Amount or sum of all line items
            CASE WHEN d.Amount > d.TotalLineItems THEN d.Amount ELSE d.TotalLineItems END as GrossBilled,
            CASE 
                WHEN d.DueDate >= GETUTCDATE() THEN 0
                WHEN d.EffectiveStrategy IS NULL OR d.EffectiveStrategy = 'None' THEN 0
                WHEN @ActivationDate IS NULL OR d.CreatedDate < @ActivationDate THEN 0
                WHEN DATEDIFF(DAY, d.DueDate, GETUTCDATE()) <= d.EffectiveGrace THEN 0
                WHEN d.PenaltyLineItems > 0 THEN 0 
                ELSE 
                    (SELECT 
                        CASE 
                            WHEN d.EffectiveStrategy = 'FlatAmount' THEN d.EffectiveValue * monthsLate
                            WHEN d.EffectiveStrategy = 'OneTimeFlat' THEN d.EffectiveValue
                            WHEN d.EffectiveStrategy = 'OneTimePercentage' THEN ROUND(d.Amount * (d.EffectiveValue / 100.0), 2)
                            WHEN d.EffectiveStrategy = 'Percentage' AND d.EffectiveCompounding = 0 THEN ROUND(d.Amount * (d.EffectiveValue / 100.0) * monthsLate, 2)
                            WHEN d.EffectiveStrategy = 'Percentage' AND d.EffectiveCompounding = 1 THEN ROUND(d.Amount * (POWER(CAST(1 + (d.EffectiveValue / 100.0) AS FLOAT), monthsLate)) - d.Amount, 2)
                            ELSE 0
                        END
                     FROM (SELECT CEILING(DATEDIFF(DAY, d.DueDate, GETUTCDATE()) / 30.44) as monthsLate) m
                    )
            END as DynamicFine
        FROM InvoiceData d
    )
    SELECT @TotalUnpaid = ISNULL(SUM(CAST((GrossBilled + DynamicFine) - TotalPaid AS DECIMAL(18,2))), 0)
    FROM CalculatedFines
    WHERE (GrossBilled + DynamicFine) - TotalPaid > 0;

    -- 2. Optimized Collected Sum
    SELECT @Collected30Days = SUM(Amount)
    FROM assoc.Payments WITH (NOLOCK)
    WHERE TenantId = @TenantId 
    AND AssociationId = @AssociationId 
    AND (@AssetId IS NULL OR AssetId = @AssetId)
    AND (
        @AssetIds IS NULL 
        OR AssetId IN (SELECT CAST(value AS INT) FROM STRING_SPLIT(@AssetIds, ','))
    )
    AND Status IN ('Paid', 'Captured', 'Completed') -- SARGable check
    AND (Notes IS NULL OR Notes NOT LIKE 'Auto-Settled%')
    AND CreatedDate >= DATEADD(DAY, -30, GETDATE());

    SELECT 
        CAST(ISNULL(@TotalUnpaid, 0) AS DECIMAL(18,2)) as TotalUnpaid, 
        CAST(ISNULL(@Collected30Days, 0) AS DECIMAL(18,2)) as Collected30Days;
END
GO