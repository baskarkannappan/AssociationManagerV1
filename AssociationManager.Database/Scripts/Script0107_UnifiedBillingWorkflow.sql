-- Script0107_UnifiedBillingWorkflow.sql
PRINT 'Applying Unified Billing Workflow changes...'
GO

-- 1. sp_Finance_GetSummaryStats (Excludes drafts)
IF EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[assoc].[sp_Finance_GetSummaryStats]') AND type in (N'P', N'PC'))
    DROP PROCEDURE [assoc].[sp_Finance_GetSummaryStats];
GO

CREATE PROCEDURE assoc.sp_Finance_GetSummaryStats
    @TenantId INT,
    @AssociationId INT = NULL,
    @AssetId INT = NULL,
    @AssetIds NVARCHAR(MAX) = NULL 
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @TotalUnpaid DECIMAL(18,2) = 0;
    DECLARE @Collected30Days DECIMAL(18,2) = 0;

    -- Total Unpaid Invoices (using TRIM and case-insensitive check)
    SELECT @TotalUnpaid = SUM(Amount)
    FROM assoc.Invoices
    WHERE TenantId = @TenantId
    AND (@AssociationId IS NULL OR AssociationId = @AssociationId)
    AND (@AssetId IS NULL OR AssetId = @AssetId)
    AND (@AssetIds IS NULL OR AssetId IN (SELECT CAST(value AS INT) FROM STRING_SPLIT(@AssetIds, ',')))
    AND LTRIM(RTRIM(Status)) IN ('Unpaid', 'unpaid', 'Partial', 'partial')
    AND LTRIM(RTRIM(Status)) NOT IN ('Draft', 'draft');

    -- Collected in last 30 days
    SELECT @Collected30Days = SUM(Amount)
    FROM assoc.Payments
    WHERE TenantId = @TenantId
    AND (@AssociationId IS NULL OR AssociationId = @AssociationId)
    AND (@AssetId IS NULL OR AssetId = @AssetId)
    AND (@AssetIds IS NULL OR AssetId IN (SELECT CAST(value AS INT) FROM STRING_SPLIT(@AssetIds, ',')))
    AND LTRIM(RTRIM(Status)) IN ('Paid', 'paid', 'Captured', 'captured', 'Completed', 'completed')
    AND (Notes IS NULL OR Notes NOT LIKE 'Auto-Settled%')
    AND CreatedDate >= DATEADD(DAY, -30, GETDATE());

    SELECT 
        CAST(ISNULL(@TotalUnpaid, 0) AS DECIMAL(18,2)) as TotalUnpaid,
        CAST(ISNULL(@Collected30Days, 0) AS DECIMAL(18,2)) as Collected30Days;
END;
GO

-- 2. sp_Invoices_GetPaged (Supports @IncludeDraft)
IF EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[assoc].[sp_Invoices_GetPaged]') AND type in (N'P', N'PC'))
    DROP PROCEDURE [assoc].[sp_Invoices_GetPaged];
GO

CREATE PROCEDURE assoc.sp_Invoices_GetPaged
    @TenantId INT,
    @AssociationId INT = NULL,
    @AssetId INT = NULL,
    @AssetIds NVARCHAR(MAX) = NULL,
    @SearchTerm NVARCHAR(255) = NULL,
    @Status NVARCHAR(50) = NULL,
    @StartDate DATETIME = NULL,
    @EndDate DATETIME = NULL,
    @PageNumber INT = 1,
    @PageSize INT = 10,
    @SortColumn NVARCHAR(50) = 'CreatedDate',
    @SortDirection NVARCHAR(10) = 'DESC',
    @IncludeDraft BIT = 0
AS
BEGIN
    SET NOCOUNT ON;
    
    DECLARE @Offset INT = (@PageNumber - 1) * @PageSize;
    
    IF @SortColumn NOT IN ('Title', 'Amount', 'DueDate', 'Status', 'CreatedDate', 'AssetName')
        SET @SortColumn = 'CreatedDate';
    
    IF @SortDirection NOT IN ('ASC', 'DESC')
        SET @SortDirection = 'DESC';

    ;WITH FilteredInvoices AS (
        SELECT 
            i.*,
            a.Name AS AssetName,
            CAST(COUNT(*) OVER() AS INT) as TotalCount,
            CAST(SUM(CASE WHEN LTRIM(RTRIM(i.Status)) IN ('Unpaid', 'unpaid', 'Partial', 'partial') THEN i.Amount ELSE 0 END) OVER() AS DECIMAL(18,2)) as TotalUnpaid
        FROM assoc.Invoices i
        LEFT JOIN assoc.Assets a ON i.AssetId = a.AssetId
        WHERE i.TenantId = @TenantId
        AND (@AssociationId IS NULL OR i.AssociationId = @AssociationId)
        AND (@AssetId IS NULL OR i.AssetId = @AssetId)
        AND (@AssetIds IS NULL OR i.AssetId IN (SELECT CAST(value AS INT) FROM STRING_SPLIT(@AssetIds, ',')))
        AND (@Status IS NULL OR i.Status = @Status)
        AND (@IncludeDraft = 1 OR i.Status != 'Draft')
        AND (@SearchTerm IS NULL OR i.Title LIKE '%' + @SearchTerm + '%' OR a.Name LIKE '%' + @SearchTerm + '%')
        AND (@StartDate IS NULL OR i.CreatedDate >= @StartDate)
        AND (@EndDate IS NULL OR i.CreatedDate <= @EndDate)
    )
    SELECT 
        * 
    FROM FilteredInvoices
    ORDER BY 
        CASE WHEN @SortDirection = 'ASC' THEN
            CASE 
                WHEN @SortColumn = 'Title' THEN Title
                WHEN @SortColumn = 'Status' THEN Status
                WHEN @SortColumn = 'AssetName' THEN AssetName
            END
        END ASC,
        CASE WHEN @SortDirection = 'DESC' THEN
            CASE 
                WHEN @SortColumn = 'Title' THEN Title
                WHEN @SortColumn = 'Status' THEN Status
                WHEN @SortColumn = 'AssetName' THEN AssetName
            END
        END DESC,
        CASE WHEN @SortDirection = 'ASC' THEN
            CASE 
                WHEN @SortColumn = 'Amount' THEN Amount
                WHEN @SortColumn = 'DueDate' THEN CAST(DueDate AS SQL_VARIANT)
                WHEN @SortColumn = 'CreatedDate' THEN CAST(CreatedDate AS SQL_VARIANT)
            END
        END ASC,
        CASE WHEN @SortDirection = 'DESC' THEN
            CASE 
                WHEN @SortColumn = 'Amount' THEN Amount
                WHEN @SortColumn = 'DueDate' THEN CAST(DueDate AS SQL_VARIANT)
                WHEN @SortColumn = 'CreatedDate' THEN CAST(CreatedDate AS SQL_VARIANT)
            END
        END DESC
    OFFSET @Offset ROWS
    FETCH NEXT @PageSize ROWS ONLY;
END;
GO

-- 3. sp_Reports_GetFinancialMetrics (Excludes Drafts)
IF EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[assoc].[sp_Reports_GetFinancialMetrics]') AND type in (N'P', N'PC'))
    DROP PROCEDURE [assoc].[sp_Reports_GetFinancialMetrics];
GO

CREATE PROCEDURE assoc.sp_Reports_GetFinancialMetrics
    @TenantId INT,
    @AssociationId INT
AS
BEGIN
    SET NOCOUNT ON;

    -- 1. Aging Calculation
    ;WITH UnpaidInvoices AS (
        SELECT 
            i.InvoiceId,
            i.DueDate,
            i.Amount + ISNULL(fines.TotalFines, 0) as TotalDue
        FROM assoc.Invoices i
        OUTER APPLY (
            SELECT SUM(li.Amount) as TotalFines 
            FROM assoc.InvoiceLineItems li 
            WHERE li.InvoiceId = i.InvoiceId 
            AND (li.ChargeName LIKE '%Penalty%' OR li.ChargeName LIKE '%Fine%')
        ) fines
        WHERE i.TenantId = @TenantId 
        AND i.AssociationId = @AssociationId 
        AND i.Status NOT IN ('Paid', 'Cancelled', 'Void', 'Draft')
    )
    SELECT 
        SUM(CASE WHEN DATEDIFF(day, DueDate, GETUTCDATE()) BETWEEN 0 AND 30 THEN TotalDue ELSE 0 END) AS Bucket0_30,
        SUM(CASE WHEN DATEDIFF(day, DueDate, GETUTCDATE()) BETWEEN 31 AND 60 THEN TotalDue ELSE 0 END) AS Bucket31_60,
        SUM(CASE WHEN DATEDIFF(day, DueDate, GETUTCDATE()) BETWEEN 61 AND 90 THEN TotalDue ELSE 0 END) AS Bucket61_90,
        SUM(CASE WHEN DATEDIFF(day, DueDate, GETUTCDATE()) > 90 THEN TotalDue ELSE 0 END) AS BucketOver90
    FROM UnpaidInvoices;

    -- 2. Monthly Collection Efficiency
    ;WITH Months AS (
        SELECT TOP 6 
            FORMAT(DATEADD(MONTH, - (ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) - 1), GETUTCDATE()), 'MMM yyyy') AS MonthLabel,
            DATEPART(MONTH, DATEADD(MONTH, - (ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) - 1), GETUTCDATE())) AS [Month],
            DATEPART(YEAR, DATEADD(MONTH, - (ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) - 1), GETUTCDATE())) AS [Year]
        FROM sys.objects
    ),
    MonthlyBilled AS (
        SELECT 
            DATEPART(MONTH, i.CreatedDate) as [Month],
            DATEPART(YEAR, i.CreatedDate) as [Year],
            SUM(i.Amount + ISNULL(fines.TotalFines, 0)) as TotalBilled
        FROM assoc.Invoices i
        OUTER APPLY (
            SELECT SUM(li.Amount) as TotalFines 
            FROM assoc.InvoiceLineItems li 
            WHERE li.InvoiceId = i.InvoiceId 
            AND (li.ChargeName LIKE '%Penalty%' OR li.ChargeName LIKE '%Fine%')
        ) fines
        WHERE i.TenantId = @TenantId AND i.AssociationId = @AssociationId
        AND i.Status != 'Draft'
        GROUP BY DATEPART(MONTH, i.CreatedDate), DATEPART(YEAR, i.CreatedDate)
    ),
    MonthlyCollected AS (
        SELECT 
            DATEPART(MONTH, i.CreatedDate) as [Month],
            DATEPART(YEAR, i.CreatedDate) as [Year],
            SUM(p.Amount) as TotalCollected
        FROM assoc.Payments p
        INNER JOIN assoc.Invoices i ON p.InvoiceId = i.InvoiceId
        WHERE p.TenantId = @TenantId AND p.AssociationId = @AssociationId
        AND p.Status IN ('Paid', 'Completed', 'Captured')
        GROUP BY DATEPART(MONTH, i.CreatedDate), DATEPART(YEAR, i.CreatedDate)
    )
    SELECT 
        m.MonthLabel as [Month],
        ISNULL(mb.TotalBilled, 0) as BilledAmount,
        ISNULL(mc.TotalCollected, 0) as CollectedAmount
    FROM Months m
    LEFT JOIN MonthlyBilled mb ON m.[Month] = mb.[Month] AND m.[Year] = mb.[Year]
    LEFT JOIN MonthlyCollected mc ON m.[Month] = mc.[Month] AND m.[Year] = mc.[Year]
    ORDER BY m.[Year] ASC, m.[Month] ASC;

    -- 3. High Level Stats
    SELECT 
        (SELECT ISNULL(SUM(Amount), 0) FROM assoc.Payments WHERE TenantId = @TenantId AND AssociationId = @AssociationId AND Status IN ('Paid', 'Completed', 'Captured')) as TotalCollectedAllTime,
        (SELECT ISNULL(SUM(Amount), 0) FROM assoc.Invoices WHERE TenantId = @TenantId AND AssociationId = @AssociationId AND Status NOT IN ('Paid', 'Cancelled', 'Draft')) as TotalUnpaidPrincipal
END;
GO

-- 4. sp_Invoices_GetUnpaidOverdue (Excludes Drafts)
IF EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[assoc].[sp_Invoices_GetUnpaidOverdue]') AND type in (N'P', N'PC'))
    DROP PROCEDURE [assoc].[sp_Invoices_GetUnpaidOverdue];
GO

CREATE PROCEDURE assoc.sp_Invoices_GetUnpaidOverdue
AS
BEGIN
    SET NOCOUNT ON;
    SELECT 
        InvoiceId, TenantId, AssociationId, AssetId, Title, [Description], Amount, DueDate, [Status], CreatedDate, IsAdvancePaid
    FROM assoc.Invoices
    WHERE [Status] NOT IN ('Paid', 'Cancelled', 'Void', 'Draft')
    AND DueDate < GETUTCDATE();
END;
GO

-- 5. sp_Invoices_GetByBatchId
IF EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[assoc].[sp_Invoices_GetByBatchId]') AND type in (N'P', N'PC'))
    DROP PROCEDURE [assoc].[sp_Invoices_GetByBatchId];
GO

CREATE PROCEDURE assoc.sp_Invoices_GetByBatchId
    @BatchId INT,
    @TenantId INT
AS
BEGIN
    SET NOCOUNT ON;
    SELECT * FROM assoc.Invoices 
    WHERE BillingBatchId = @BatchId 
    AND TenantId = @TenantId;
END;
GO

-- 6. sp_Invoices_Update
IF EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[assoc].[sp_Invoices_Update]') AND type in (N'P', N'PC'))
    DROP PROCEDURE [assoc].[sp_Invoices_Update];
GO

CREATE PROCEDURE assoc.sp_Invoices_Update
    @Id INT,
    @TenantId INT,
    @AssociationId INT,
    @AssetId INT = NULL,
    @BillingBatchId INT = NULL,
    @Title NVARCHAR(200),
    @Description NVARCHAR(500),
    @Amount DECIMAL(18, 2),
    @DueDate DATETIME,
    @Status NVARCHAR(50)
AS
BEGIN
    SET NOCOUNT ON;
    UPDATE assoc.Invoices
    SET 
        AssetId = @AssetId,
        BillingBatchId = @BillingBatchId,
        Title = @Title,
        [Description] = @Description,
        Amount = @Amount,
        DueDate = @DueDate,
        [Status] = @Status
    WHERE InvoiceId = @Id
    AND TenantId = @TenantId
    AND AssociationId = @AssociationId;
END;
GO

-- 7. sp_InvoiceLineItems_DeleteByInvoiceId
IF EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[assoc].[sp_InvoiceLineItems_DeleteByInvoiceId]') AND type in (N'P', N'PC'))
    DROP PROCEDURE [assoc].[sp_InvoiceLineItems_DeleteByInvoiceId];
GO

CREATE PROCEDURE assoc.sp_InvoiceLineItems_DeleteByInvoiceId
    @InvoiceId INT
AS
BEGIN
    SET NOCOUNT ON;
    DELETE FROM assoc.InvoiceLineItems WHERE InvoiceId = @InvoiceId;
END;
GO

PRINT 'Unified Billing Workflow changes applied successfully.'
GO
