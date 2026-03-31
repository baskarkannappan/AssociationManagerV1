-- Script0061_PaginatedInvoices.sql
-- High-performance Server-Side Paging for Invoices

-- 1. Create Paginated Invoices Procedure
CREATE OR ALTER PROCEDURE assoc.sp_Invoices_GetPaged
    @TenantId INT,
    @AssociationId INT = NULL,
    @AssetId INT = NULL,
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
    
    -- Calculate Offset
    DECLARE @Offset INT = (@PageNumber - 1) * @PageSize;
    
    -- Sorting Safety
    IF @SortColumn NOT IN ('Title', 'Amount', 'DueDate', 'Status', 'CreatedDate', 'AssetName')
        SET @SortColumn = 'CreatedDate';
    
    IF @SortDirection NOT IN ('ASC', 'DESC')
        SET @SortDirection = 'DESC';

    -- CTE for Filtering and Paging
    ;WITH FilteredInvoices AS (
        SELECT 
            i.*,
            a.Name AS AssetName,
            COUNT(*) OVER() as TotalCount,
            SUM(CASE WHEN i.Status = 'Unpaid' THEN i.Amount ELSE 0 END) OVER() as TotalUnpaid
        FROM assoc.Invoices i
        LEFT JOIN assoc.Assets a ON i.AssetId = a.AssetId
        WHERE i.TenantId = @TenantId
        AND (@AssociationId IS NULL OR i.AssociationId = @AssociationId)
        AND (@AssetId IS NULL OR i.AssetId = @AssetId)
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

-- 2. Create Summary Stats Procedure for Dashboard Header
CREATE OR ALTER PROCEDURE assoc.sp_Finance_GetSummaryStats
    @TenantId INT,
    @AssociationId INT = NULL,
    @AssetId INT = NULL
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @TotalUnpaid DECIMAL(18,2) = 0;
    DECLARE @Collected30Days DECIMAL(18,2) = 0;

    -- Total Unpaid Invoices
    SELECT @TotalUnpaid = SUM(Amount)
    FROM assoc.Invoices
    WHERE TenantId = @TenantId
    AND (@AssociationId IS NULL OR AssociationId = @AssociationId)
    AND (@AssetId IS NULL OR AssetId = @AssetId)
    AND Status = 'Unpaid';

    -- Collected in last 30 days
    SELECT @Collected30Days = SUM(Amount)
    FROM assoc.Payments
    WHERE TenantId = @TenantId
    AND (@AssociationId IS NULL OR AssociationId = @AssociationId)
    AND (@AssetId IS NULL OR AssetId = @AssetId)
    AND Status = 'Paid'
    AND CreatedDate >= DATEADD(DAY, -30, GETDATE());

    SELECT 
        ISNULL(@TotalUnpaid, 0) as TotalUnpaid,
        ISNULL(@Collected30Days, 0) as Collected30Days;
END;
GO
