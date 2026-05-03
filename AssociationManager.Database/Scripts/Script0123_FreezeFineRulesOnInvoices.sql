-- Script0123_FreezeFineRulesOnInvoices.sql
-- Goal: Persist fine rules on invoices at creation time to prevent historical calculation drift.

-- 1. Add snapshot columns to Invoices
IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID('assoc.Invoices') AND name = 'FineStrategy')
BEGIN
    ALTER TABLE assoc.Invoices ADD 
        FineStrategy NVARCHAR(50) NULL,
        FineValue DECIMAL(18,2) NULL,
        FineGracePeriod INT NULL,
        FineIsCompounding BIT NULL;
END
GO

-- 2. Backfill existing unpaid invoices with current association-level fine rules
-- This "locks" legacy data to the state at the time of this migration.
UPDATE i
SET 
    i.FineStrategy = fs.StrategyType,
    i.FineValue = fs.FineValue,
    i.FineGracePeriod = fs.GracePeriodDays,
    i.FineIsCompounding = fs.IsCompounding
FROM assoc.Invoices i
JOIN assoc.FineSettings fs ON i.AssociationId = fs.AssociationId AND i.TenantId = fs.TenantId
WHERE i.Status NOT IN ('Paid', 'Cancelled', 'Void')
AND i.FineStrategy IS NULL; -- Only backfill if not already set
GO

-- 3. Redeploy procedures with snapshot/priority logic
-- (Invoices procs, Dashboard, Balances, Summary)

-- sp_Invoices_Create
CREATE OR ALTER PROCEDURE assoc.sp_Invoices_Create 
    @TenantId INT, 
    @AssociationId INT, 
    @AssetId INT = NULL, 
    @BillingBatchId INT = NULL, 
    @Title NVARCHAR(200), 
    @Description NVARCHAR(MAX) = NULL, 
    @Amount DECIMAL(18, 2), 
    @DueDate DATETIME, 
    @Status NVARCHAR(50), 
    @CreatedDate DATETIME 
AS 
BEGIN 
    SET NOCOUNT ON;
    DECLARE @FineStrategy NVARCHAR(50), @FineValue DECIMAL(18,2), @FineGracePeriod INT, @FineIsCompounding BIT;
    SELECT @FineStrategy = StrategyType, @FineValue = FineValue, @FineGracePeriod = GracePeriodDays, @FineIsCompounding = IsCompounding
    FROM assoc.FineSettings WHERE AssociationId = @AssociationId AND TenantId = @TenantId;
    INSERT INTO assoc.Invoices (TenantId, AssociationId, AssetId, BillingBatchId, Title, Description, Amount, DueDate, Status, CreatedDate, FineStrategy, FineValue, FineGracePeriod, FineIsCompounding) 
    VALUES (@TenantId, @AssociationId, @AssetId, @BillingBatchId, @Title, @Description, @Amount, @DueDate, @Status, @CreatedDate, @FineStrategy, @FineValue, @FineGracePeriod, @FineIsCompounding); 
    SELECT SCOPE_IDENTITY(); 
END
GO

-- sp_Invoices_CreateBulk
CREATE OR ALTER PROCEDURE [assoc].[sp_Invoices_CreateBulk]
    @TenantId INT, @AssociationId INT, @Invoices [assoc].[typ_InvoiceBatch] READONLY, @LineItems [assoc].[typ_InvoiceLineItemBatch] READONLY
AS
BEGIN
    SET NOCOUNT ON; SET XACT_ABORT ON;
    BEGIN TRANSACTION;
    DECLARE @IdMapping TABLE (InvoiceId INT, TempId NVARCHAR(100));
    MERGE INTO [assoc].[Invoices] AS Target
    USING (SELECT s.*, fs.StrategyType, fs.FineValue, fs.GracePeriodDays, fs.IsCompounding FROM @Invoices s OUTER APPLY (SELECT TOP 1 StrategyType, FineValue, GracePeriodDays, IsCompounding FROM assoc.FineSettings WHERE AssociationId = @AssociationId AND TenantId = @TenantId) fs) AS Source
    ON 1 = 0 WHEN NOT MATCHED THEN
        INSERT (TenantId, AssociationId, AssetId, BillingBatchId, Title, Description, Amount, DueDate, Status, CreatedDate, FineStrategy, FineValue, FineGracePeriod, FineIsCompounding)
        VALUES (@TenantId, @AssociationId, Source.AssetId, Source.BillingBatchId, Source.Title, Source.Description, Source.Amount, Source.DueDate, Source.Status, Source.CreatedDate, Source.StrategyType, Source.FineValue, Source.GracePeriodDays, Source.IsCompounding)
    OUTPUT inserted.InvoiceId, Source.TempId INTO @IdMapping(InvoiceId, TempId);
    INSERT INTO [assoc].[InvoiceLineItems] (InvoiceId, ChargeName, Amount, Description, TariffLayerId, Rate)
    SELECT m.InvoiceId, li.ChargeName, li.Amount, li.Description, li.TariffLayerId, li.Rate FROM @LineItems li INNER JOIN @IdMapping m ON li.TempInvoiceId = m.TempId;
    COMMIT TRANSACTION;
    SELECT InvoiceId, TempId FROM @IdMapping;
END
GO

-- sp_Dashboard_GetNetOutstanding
CREATE OR ALTER PROCEDURE assoc.sp_Dashboard_GetNetOutstanding
    @TenantId INT, @AssociationId INT
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @StrategyType NVARCHAR(50), @FineValue DECIMAL(18,2), @GracePeriodDays INT, @IsCompounding BIT, @ActivationDate DATETIME;
    SELECT TOP 1 @StrategyType = StrategyType, @FineValue = FineValue, @GracePeriodDays = GracePeriodDays, @IsCompounding = IsCompounding, @ActivationDate = ActivationDate FROM assoc.FineSettings WHERE AssociationId = @AssociationId AND TenantId = @TenantId;
    WITH InvoiceData AS (
        SELECT i.InvoiceId, i.DueDate, i.CreatedDate, i.Amount, i.[Status], ISNULL(items.TotalLineItems, 0) as TotalLineItems, ISNULL(items.PenaltyLineItems, 0) as PenaltyLineItems, ISNULL(payments.TotalPaid, 0) as TotalPaid, COALESCE(i.FineStrategy, @StrategyType) as EffectiveStrategy, COALESCE(i.FineValue, @FineValue) as EffectiveValue, COALESCE(i.FineGracePeriod, @GracePeriodDays) as EffectiveGrace, COALESCE(i.FineIsCompounding, @IsCompounding) as EffectiveCompounding
        FROM assoc.Invoices i WITH (NOLOCK)
        OUTER APPLY (SELECT SUM(li.Amount) as TotalLineItems, SUM(CASE WHEN li.ChargeName LIKE '%Penalty%' OR li.ChargeName LIKE '%Fine%' OR li.ChargeName LIKE '%Late%' OR li.ChargeName LIKE '%Interest%' THEN li.Amount ELSE 0 END) as PenaltyLineItems FROM assoc.InvoiceLineItems li WITH (NOLOCK) WHERE li.InvoiceId = i.InvoiceId ) items
        OUTER APPLY (SELECT SUM(p.Amount) as TotalPaid FROM assoc.Payments p WITH (NOLOCK) WHERE p.InvoiceId = i.InvoiceId AND p.Status IN ('Paid', 'Completed', 'Captured')) payments
        WHERE i.TenantId = @TenantId AND i.AssociationId = @AssociationId AND i.[Status] NOT IN ('Paid', 'Cancelled', 'Void', 'Draft')
    ),
    CalculatedFines AS (
        SELECT d.*, CASE WHEN d.Amount > d.TotalLineItems THEN d.Amount ELSE d.TotalLineItems END as GrossBilled,
            CASE WHEN d.DueDate >= GETUTCDATE() THEN 0 WHEN d.EffectiveStrategy IS NULL OR d.EffectiveStrategy = 'None' THEN 0 WHEN @ActivationDate IS NULL OR d.CreatedDate < @ActivationDate THEN 0 WHEN DATEDIFF(DAY, d.DueDate, GETUTCDATE()) <= d.EffectiveGrace THEN 0 WHEN d.PenaltyLineItems > 0 THEN 0 ELSE 
                (SELECT CASE WHEN d.EffectiveStrategy = 'FlatAmount' THEN d.EffectiveValue * monthsLate WHEN d.EffectiveStrategy = 'OneTimeFlat' THEN d.EffectiveValue WHEN d.EffectiveStrategy = 'OneTimePercentage' THEN ROUND(d.Amount * (d.EffectiveValue / 100.0), 2) WHEN d.EffectiveStrategy = 'Percentage' AND d.EffectiveCompounding = 0 THEN ROUND(d.Amount * (d.EffectiveValue / 100.0) * monthsLate, 2) WHEN d.EffectiveStrategy = 'Percentage' AND d.EffectiveCompounding = 1 THEN ROUND(d.Amount * (POWER(CAST(1 + (d.EffectiveValue / 100.0) AS FLOAT), monthsLate)) - d.Amount, 2) ELSE 0 END FROM (SELECT CEILING(DATEDIFF(DAY, d.DueDate, GETUTCDATE()) / 30.44) as monthsLate) m)
            END as DynamicFine FROM InvoiceData d
    )
    SELECT CAST(ISNULL(SUM((GrossBilled + DynamicFine) - TotalPaid), 0) AS DECIMAL(18,2)) FROM CalculatedFines WHERE (GrossBilled + DynamicFine) - TotalPaid > 0;
END
GO

-- sp_Finance_GetSummaryStats
CREATE OR ALTER PROCEDURE assoc.sp_Finance_GetSummaryStats
    @TenantId INT, @AssociationId INT, @AssetId INT = NULL, @AssetIds NVARCHAR(MAX) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @TotalUnpaid DECIMAL(18,2) = 0, @Collected30Days DECIMAL(18,2) = 0;
    DECLARE @StrategyType NVARCHAR(50), @FineValue DECIMAL(18,2), @GracePeriodDays INT, @IsCompounding BIT, @ActivationDate DATETIME;
    SELECT TOP 1 @StrategyType = StrategyType, @FineValue = FineValue, @GracePeriodDays = GracePeriodDays, @IsCompounding = IsCompounding, @ActivationDate = ActivationDate FROM assoc.FineSettings WHERE AssociationId = @AssociationId AND TenantId = @TenantId;
    WITH InvoiceData AS (
        SELECT i.InvoiceId, i.DueDate, i.CreatedDate, i.Amount, i.[Status], i.AssetId, ISNULL(items.TotalLineItems, 0) as TotalLineItems, ISNULL(items.PenaltyLineItems, 0) as PenaltyLineItems, ISNULL(payments.TotalPaid, 0) as TotalPaid, COALESCE(i.FineStrategy, @StrategyType) as EffectiveStrategy, COALESCE(i.FineValue, @FineValue) as EffectiveValue, COALESCE(i.FineGracePeriod, @GracePeriodDays) as EffectiveGrace, COALESCE(i.FineIsCompounding, @IsCompounding) as EffectiveCompounding
        FROM assoc.Invoices i WITH (NOLOCK)
        OUTER APPLY (SELECT SUM(li.Amount) as TotalLineItems, SUM(CASE WHEN li.ChargeName LIKE '%Penalty%' OR li.ChargeName LIKE '%Fine%' OR li.ChargeName LIKE '%Late%' OR li.ChargeName LIKE '%Interest%' THEN li.Amount ELSE 0 END) as PenaltyLineItems FROM assoc.InvoiceLineItems li WITH (NOLOCK) WHERE li.InvoiceId = i.InvoiceId ) items
        OUTER APPLY (SELECT SUM(p.Amount) as TotalPaid FROM assoc.Payments p WITH (NOLOCK) WHERE p.InvoiceId = i.InvoiceId AND p.Status IN ('Paid', 'Completed', 'Captured')) payments
        WHERE i.TenantId = @TenantId AND i.AssociationId = @AssociationId AND i.[Status] NOT IN ('Paid', 'Cancelled', 'Void', 'Draft') AND (@AssetId IS NULL OR i.AssetId = @AssetId) AND (@AssetIds IS NULL OR i.AssetId IN (SELECT CAST(value AS INT) FROM STRING_SPLIT(@AssetIds, ',')))
    ),
    CalculatedFines AS (
        SELECT d.*, CASE WHEN d.Amount > d.TotalLineItems THEN d.Amount ELSE d.TotalLineItems END as GrossBilled,
            CASE WHEN d.DueDate >= GETUTCDATE() THEN 0 WHEN d.EffectiveStrategy IS NULL OR d.EffectiveStrategy = 'None' THEN 0 WHEN @ActivationDate IS NULL OR d.CreatedDate < @ActivationDate THEN 0 WHEN DATEDIFF(DAY, d.DueDate, GETUTCDATE()) <= d.EffectiveGrace THEN 0 WHEN d.PenaltyLineItems > 0 THEN 0 ELSE 
                (SELECT CASE WHEN d.EffectiveStrategy = 'FlatAmount' THEN d.EffectiveValue * monthsLate WHEN d.EffectiveStrategy = 'OneTimeFlat' THEN d.EffectiveValue WHEN d.EffectiveStrategy = 'OneTimePercentage' THEN ROUND(d.Amount * (d.EffectiveValue / 100.0), 2) WHEN d.EffectiveStrategy = 'Percentage' AND d.EffectiveCompounding = 0 THEN ROUND(d.Amount * (d.EffectiveValue / 100.0) * monthsLate, 2) WHEN d.EffectiveStrategy = 'Percentage' AND d.EffectiveCompounding = 1 THEN ROUND(d.Amount * (POWER(CAST(1 + (d.EffectiveValue / 100.0) AS FLOAT), monthsLate)) - d.Amount, 2) ELSE 0 END FROM (SELECT CEILING(DATEDIFF(DAY, d.DueDate, GETUTCDATE()) / 30.44) as monthsLate) m)
            END as DynamicFine FROM InvoiceData d
    )
    SELECT @TotalUnpaid = ISNULL(SUM(CAST((GrossBilled + DynamicFine) - TotalPaid AS DECIMAL(18,2))), 0) FROM CalculatedFines WHERE (GrossBilled + DynamicFine) - TotalPaid > 0;
    SELECT @Collected30Days = SUM(Amount) FROM assoc.Payments WITH (NOLOCK) WHERE TenantId = @TenantId AND AssociationId = @AssociationId AND (@AssetId IS NULL OR AssetId = @AssetId) AND (@AssetIds IS NULL OR AssetId IN (SELECT CAST(value AS INT) FROM STRING_SPLIT(@AssetIds, ','))) AND Status IN ('Paid', 'Captured', 'Completed') AND (Notes IS NULL OR Notes NOT LIKE 'Auto-Settled%') AND CreatedDate >= DATEADD(DAY, -30, GETDATE());
    SELECT CAST(ISNULL(@TotalUnpaid, 0) AS DECIMAL(18,2)) as TotalUnpaid, CAST(ISNULL(@Collected30Days, 0) AS DECIMAL(18,2)) as Collected30Days;
END
GO
