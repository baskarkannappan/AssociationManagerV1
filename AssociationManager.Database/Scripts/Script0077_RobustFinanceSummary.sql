-- Script0077_RobustFinanceSummary.sql
-- Improve robustness of status comparisons in finance-related procedures.

PRINT 'Updating assoc.sp_Finance_GetSummaryStats and assoc.sp_Invoices_GetPaged for robustness...'
GO

-- 1. Update Summary Stats with robust status and trimming
CREATE OR ALTER PROCEDURE assoc.sp_Finance_GetSummaryStats
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
    AND LTRIM(RTRIM(Status)) IN ('Unpaid', 'unpaid', 'Partial', 'partial');

    -- Collected in last 30 days
    -- Includes captured gateway payments and manual payments, excludes internal auto-settlements
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

-- 2. Update GetPaged with robust status for TotalUnpaid metadata
CREATE OR ALTER PROCEDURE assoc.sp_Invoices_GetPaged
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
    @SortDirection NVARCHAR(10) = 'DESC'
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
            CAST(CASE WHEN EXISTS (SELECT 1 FROM assoc.Payments p WHERE p.InvoiceId = i.InvoiceId AND p.Notes LIKE '%Advance%') THEN 1 ELSE 0 END AS BIT) AS IsAdvancePaid,
            CAST(COUNT(*) OVER() AS INT) as TotalCount,
            CAST(SUM(CASE WHEN LTRIM(RTRIM(i.Status)) IN ('Unpaid', 'unpaid', 'Partial', 'partial') THEN i.Amount ELSE 0 END) OVER() AS DECIMAL(18,2)) as TotalUnpaid
        FROM assoc.Invoices i
        LEFT JOIN assoc.Assets a ON i.AssetId = a.AssetId
        WHERE i.TenantId = @TenantId
        AND (@AssociationId IS NULL OR i.AssociationId = @AssociationId)
        AND (@AssetId IS NULL OR i.AssetId = @AssetId)
        AND (@AssetIds IS NULL OR i.AssetId IN (SELECT CAST(value AS INT) FROM STRING_SPLIT(@AssetIds, ',')))
        AND (@Status IS NULL OR i.Status = @Status)
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

PRINT 'Script 0077 Complete.'
GO
