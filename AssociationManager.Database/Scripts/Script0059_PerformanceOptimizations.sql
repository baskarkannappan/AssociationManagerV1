-- Script0059_PerformanceOptimizations.sql
-- Goal: Fix Dashboard Timeout issues by adding indexes and refactoring financial procedures for high performance.

-- 1. Create Missing Indexes
IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = 'IX_InvoiceLineItems_InvoiceId' AND object_id = OBJECT_ID('assoc.InvoiceLineItems'))
BEGIN
    CREATE NONCLUSTERED INDEX [IX_InvoiceLineItems_InvoiceId]
        ON [assoc].[InvoiceLineItems]([InvoiceId] ASC)
        INCLUDE ([Amount], [ChargeName]);
END

IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = 'IX_Payments_Performance' AND object_id = OBJECT_ID('assoc.Payments'))
BEGIN
    CREATE NONCLUSTERED INDEX [IX_Payments_Performance]
        ON [assoc].[Payments]([AssociationId] ASC, [Status] ASC, [CreatedDate] ASC)
        INCLUDE ([Amount]);
END

IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = 'IX_Invoices_Summary' AND object_id = OBJECT_ID('assoc.Invoices'))
BEGIN
    CREATE NONCLUSTERED INDEX [IX_Invoices_Summary]
        ON [assoc].[Invoices]([AssociationId] ASC, [Status] ASC, [TenantId] ASC)
        INCLUDE ([Amount], [AssetId]);
END

GO

-- 2. Refactor sp_Finance_GetSummaryStats (High Performance Logic)
PRINT 'Refactoring assoc.sp_Finance_GetSummaryStats...';
GO
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

    -- A. Calculate Principal Sum
    SELECT @TotalUnpaid = ISNULL(SUM(i.Amount), 0)
    FROM assoc.Invoices i
    WHERE i.TenantId = @TenantId 
    AND i.AssociationId = @AssociationId 
    AND (@AssetId IS NULL OR i.AssetId = @AssetId)
    AND (@AssetIds IS NULL OR i.AssetId IN (SELECT CAST(value AS INT) FROM STRING_SPLIT(@AssetIds, ',')))
    AND i.Status IN ('Unpaid', 'Partial') 
    AND i.Status NOT IN ('Draft', 'Cancelled', 'Void');

    -- B. Add Penalties/Fines via indexed join (Avoids expensive OUTER APPLY)
    SELECT @TotalUnpaid = @TotalUnpaid + ISNULL(SUM(li.Amount), 0)
    FROM assoc.InvoiceLineItems li
    INNER JOIN assoc.Invoices i ON i.InvoiceId = li.InvoiceId
    WHERE i.TenantId = @TenantId 
    AND i.AssociationId = @AssociationId 
    AND (@AssetId IS NULL OR i.AssetId = @AssetId)
    AND (@AssetIds IS NULL OR i.AssetId IN (SELECT CAST(value AS INT) FROM STRING_SPLIT(@AssetIds, ',')))
    AND i.Status IN ('Unpaid', 'Partial') 
    AND (li.ChargeName LIKE '%Penalty%' OR li.ChargeName LIKE '%Fine%');

    -- C. Optimized Collected Sum
    SELECT @Collected30Days = ISNULL(SUM(Amount), 0)
    FROM assoc.Payments
    WHERE TenantId = @TenantId 
    AND AssociationId = @AssociationId 
    AND (@AssetId IS NULL OR AssetId = @AssetId)
    AND (@AssetIds IS NULL OR AssetId IN (SELECT CAST(value AS INT) FROM STRING_SPLIT(@AssetIds, ',')))
    AND Status IN ('Paid', 'Captured', 'Completed') 
    AND (Notes IS NULL OR Notes NOT LIKE 'Auto-Settled%')
    AND CreatedDate >= DATEADD(DAY, -30, GETDATE());

    SELECT 
        CAST(ISNULL(@TotalUnpaid, 0) AS DECIMAL(18,2)) as TotalUnpaid, 
        CAST(ISNULL(@Collected30Days, 0) AS DECIMAL(18,2)) as Collected30Days;
END
GO

-- 3. Refactor sp_Finance_GetAssociationSummary
PRINT 'Refactoring assoc.sp_Finance_GetAssociationSummary...';
GO
CREATE OR ALTER PROCEDURE assoc.sp_Finance_GetAssociationSummary
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
GO

-- 4. Refactor sp_Dashboard_GetNetOutstanding
PRINT 'Refactoring assoc.sp_Dashboard_GetNetOutstanding...';
GO
CREATE OR ALTER PROCEDURE assoc.sp_Dashboard_GetNetOutstanding
    @TenantId INT,
    @AssociationId INT
AS
BEGIN
    SET NOCOUNT ON;
    
    DECLARE @TotalOutstanding DECIMAL(18,2) = 0;

    SELECT @TotalOutstanding = ISNULL(SUM(Amount), 0)
    FROM assoc.Invoices
    WHERE TenantId = @TenantId AND AssociationId = @AssociationId
    AND Status NOT IN ('Paid', 'Cancelled', 'Void', 'Draft', 'deleted');

    SELECT @TotalOutstanding = @TotalOutstanding + ISNULL(SUM(li.Amount), 0)
    FROM assoc.InvoiceLineItems li
    INNER JOIN assoc.Invoices i ON i.InvoiceId = li.InvoiceId
    WHERE i.TenantId = @TenantId AND i.AssociationId = @AssociationId
    AND i.Status NOT IN ('Paid', 'Cancelled', 'Void', 'Draft', 'deleted')
    AND (li.ChargeName LIKE '%Penalty%' OR li.ChargeName LIKE '%Fine%');

    SELECT @TotalOutstanding as TotalOutstanding;
END
GO

-- 5. Refactor sp_AssociationBalances_Sync (remove OUTER APPLY, use fast two-query pattern)
PRINT 'Refactoring assoc.sp_AssociationBalances_Sync...';
GO
CREATE OR ALTER PROCEDURE assoc.sp_AssociationBalances_Sync
    @TenantId INT,
    @AssociationId INT
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @LiveOutstanding DECIMAL(18,2) = 0;
    DECLARE @LiveCredits DECIMAL(18,2) = 0;
    DECLARE @LiveUnitsWithCredit INT = 0;

    -- Principal (uses IX_Invoices_Summary index)
    SELECT @LiveOutstanding = ISNULL(SUM(Amount), 0)
    FROM assoc.Invoices
    WHERE TenantId = @TenantId AND AssociationId = @AssociationId
    AND Status IN ('Unpaid', 'Partial')
    AND Status NOT IN ('Draft', 'Cancelled', 'Void');

    -- Penalties (uses IX_InvoiceLineItems_InvoiceId)
    SELECT @LiveOutstanding = @LiveOutstanding + ISNULL(SUM(li.Amount), 0)
    FROM assoc.InvoiceLineItems li
    INNER JOIN assoc.Invoices i ON i.InvoiceId = li.InvoiceId
    WHERE i.TenantId = @TenantId AND i.AssociationId = @AssociationId
    AND i.Status IN ('Unpaid', 'Partial')
    AND (li.ChargeName LIKE '%Penalty%' OR li.ChargeName LIKE '%Fine%');

    -- Credits from Transactions (uses IX_Transactions_WalletSearch)
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
        @LiveCredits = ISNULL(SUM(Balance), 0),
        @LiveUnitsWithCredit = COUNT(*)
    FROM WalletBalances
    WHERE Balance > 0;

    -- Upsert into Snapshot Table
    IF EXISTS (SELECT 1 FROM assoc.AssociationBalances WHERE AssociationId = @AssociationId)
    BEGIN
        UPDATE assoc.AssociationBalances
        SET TotalOutstanding = @LiveOutstanding,
            TotalAdvanceCredits = @LiveCredits,
            UnitsWithCredit = @LiveUnitsWithCredit,
            LastUpdated = GETDATE()
        WHERE AssociationId = @AssociationId;
    END
    ELSE
    BEGIN
        INSERT INTO assoc.AssociationBalances (AssociationId, TenantId, TotalOutstanding, TotalAdvanceCredits, UnitsWithCredit, LastUpdated)
        VALUES (@AssociationId, @TenantId, @LiveOutstanding, @LiveCredits, @LiveUnitsWithCredit, GETDATE());
    END
END
GO

-- 6. Seed AssociationBalances snapshot for all associations to warm the cache immediately
PRINT 'Seeding AssociationBalances snapshot...';

DECLARE @assocId INT, @tid INT;
DECLARE balance_cur CURSOR FOR
    SELECT DISTINCT AssociationId, TenantId FROM corp.Associations WHERE TenantId IS NOT NULL;

OPEN balance_cur;
FETCH NEXT FROM balance_cur INTO @assocId, @tid;
WHILE @@FETCH_STATUS = 0
BEGIN
    IF NOT EXISTS (SELECT 1 FROM assoc.AssociationBalances WHERE AssociationId = @assocId)
    BEGIN
        EXEC assoc.sp_AssociationBalances_Sync @TenantId = @tid, @AssociationId = @assocId;
    END
    FETCH NEXT FROM balance_cur INTO @assocId, @tid;
END

CLOSE balance_cur;
DEALLOCATE balance_cur;

PRINT 'Performance optimization script completed.';
