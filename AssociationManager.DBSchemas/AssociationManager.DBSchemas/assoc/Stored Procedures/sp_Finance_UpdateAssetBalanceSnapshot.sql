CREATE PROCEDURE assoc.sp_Finance_UpdateAssetBalanceSnapshot
    @AssetId INT,
    @TenantId INT,
    @AssociationId INT
AS
BEGIN
    SET NOCOUNT ON;

    -- 1. Get Fine Settings
    DECLARE @StrategyType NVARCHAR(50), @FineValue DECIMAL(18,2), @GracePeriodDays INT, @IsCompounding BIT, @ActivationDate DATETIME;
    SELECT TOP 1 @StrategyType = StrategyType, @FineValue = FineValue, @GracePeriodDays = GracePeriodDays, @IsCompounding = IsCompounding, @ActivationDate = ActivationDate 
    FROM assoc.FineSettings 
    WHERE AssociationId = @AssociationId AND TenantId = @TenantId;

    -- 2. Calculate Current Totals for the Asset
    DECLARE @Outstanding DECIMAL(18,2) = 0;
    DECLARE @Paid DECIMAL(18,2) = 0;
    DECLARE @Advance DECIMAL(18,2) = 0;

    -- A. Calculate Invoiced Totals (including Dynamic Fines)
    WITH InvoiceData AS (
        SELECT 
            i.InvoiceId, i.Amount,
            ISNULL(items.TotalLineItems, 0) as TotalLineItems, 
            ISNULL(items.PenaltyLineItems, 0) as PenaltyLineItems, 
            ISNULL(payments.TotalPaid, 0) as TotalPaid, 
            COALESCE(i.FineStrategy, @StrategyType) as EffectiveStrategy, 
            COALESCE(i.FineValue, @FineValue) as EffectiveValue, 
            COALESCE(i.FineGracePeriod, @GracePeriodDays) as EffectiveGrace, 
            COALESCE(i.FineIsCompounding, @IsCompounding) as EffectiveCompounding,
            i.DueDate, i.CreatedDate
        FROM assoc.Invoices i WITH (NOLOCK)
        OUTER APPLY (
            SELECT 
                SUM(li.Amount) as TotalLineItems, 
                SUM(CASE WHEN li.ChargeName LIKE '%Penalty%' OR li.ChargeName LIKE '%Fine%' OR li.ChargeName LIKE '%Late%' OR li.ChargeName LIKE '%Interest%' THEN li.Amount ELSE 0 END) as PenaltyLineItems 
            FROM assoc.InvoiceLineItems li WITH (NOLOCK) 
            WHERE li.InvoiceId = i.InvoiceId 
        ) items
        OUTER APPLY (
            SELECT SUM(p.Amount) as TotalPaid 
            FROM assoc.Payments p WITH (NOLOCK) 
            WHERE p.InvoiceId = i.InvoiceId AND p.Status IN ('Paid', 'Completed', 'Captured')
        ) payments
        WHERE i.AssetId = @AssetId AND i.AssociationId = @AssociationId 
        AND i.[Status] NOT IN ('Cancelled', 'Void', 'Draft')
    ),
    CalculatedFines AS (
        SELECT 
            d.*, 
            CASE WHEN d.Amount > d.TotalLineItems THEN d.Amount ELSE d.TotalLineItems END as GrossBilled,
            CASE 
                WHEN d.DueDate >= GETUTCDATE() THEN 0 
                WHEN d.EffectiveStrategy IS NULL OR d.EffectiveStrategy = 'None' THEN 0 
                WHEN @ActivationDate IS NULL OR d.CreatedDate < @ActivationDate THEN 0 
                WHEN DATEDIFF(DAY, d.DueDate, GETUTCDATE()) <= d.EffectiveGrace THEN 0 
                WHEN d.PenaltyLineItems > 0 THEN 0 
                ELSE 
                (
                    SELECT CASE 
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
    SELECT 
        @Outstanding = SUM(GrossBilled + DynamicFine),
        @Paid = SUM(TotalPaid)
    FROM CalculatedFines;

    -- B. Calculate Advance Credits
    DECLARE @TotalCredits DECIMAL(18,2) = 0;
    DECLARE @TotalSettlements DECIMAL(18,2) = 0;

    SELECT @TotalCredits = ISNULL(SUM(p.Amount), 0)
    FROM assoc.Payments p WITH (NOLOCK)
    WHERE p.AssetId = @AssetId AND p.AssociationId = @AssociationId 
    AND p.InvoiceId IS NULL AND p.Status IN ('Completed', 'Paid');

    SELECT @TotalSettlements = ISNULL(SUM(t.Amount), 0)
    FROM assoc.Transactions t WITH (NOLOCK)
    WHERE t.AssetId = @AssetId AND t.AssociationId = @AssociationId 
    AND t.Type = 'Debit' AND t.Category IN ('Credit Settlement', 'Internal Credit Transfer');

    SET @Advance = @TotalCredits - @TotalSettlements;

    -- 3. Upsert into Snapshot Table
    IF EXISTS (SELECT 1 FROM assoc.AssetBalancesSnapshot WHERE AssetId = @AssetId)
    BEGIN
        UPDATE assoc.AssetBalancesSnapshot
        SET OutstandingAmount = ISNULL(@Outstanding, 0),
            PaidAmount = ISNULL(@Paid, 0),
            AdvanceBalance = ISNULL(@Advance, 0),
            LastUpdated = GETUTCDATE()
        WHERE AssetId = @AssetId;
    END
    ELSE
    BEGIN
        INSERT INTO assoc.AssetBalancesSnapshot (AssetId, TenantId, AssociationId, OutstandingAmount, PaidAmount, AdvanceBalance, LastUpdated)
        VALUES (@AssetId, @TenantId, @AssociationId, ISNULL(@Outstanding, 0), ISNULL(@Paid, 0), ISNULL(@Advance, 0), GETUTCDATE());
    END
END
GO
