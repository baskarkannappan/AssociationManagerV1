-- Script0070_FixPaginatedAdvances.sql
-- Fix: Using LEFT JOINs to ensure all advances (even those without AssetId) appear.

CREATE   PROCEDURE assoc.sp_Payments_GetAdvancesPaged
    @TenantId INT,
    @AssociationId INT = NULL,
    @UserId INT = NULL,
    @AssetId INT = NULL,
    @SearchTerm NVARCHAR(255) = NULL,
    @Status NVARCHAR(50) = NULL,
    @StartDate DATETIME = NULL,
    @EndDate DATETIME = NULL,
    @PageNumber INT = 1,
    @PageSize INT = 10,
    @SortColumn NVARCHAR(50) = 'Date',
    @SortDirection NVARCHAR(10) = 'DESC'
AS
BEGIN
    SET NOCOUNT ON;
    
    -- Calculate Offset
    DECLARE @Offset INT = (@PageNumber - 1) * @PageSize;
    
    -- Sorting Safety
    IF @SortColumn NOT IN ('ResidentName', 'UnitName', 'Amount', 'Date', 'Status', 'ReferenceId')
        SET @SortColumn = 'Date';
    
    IF @SortDirection NOT IN ('ASC', 'DESC')
        SET @SortDirection = 'DESC';

    -- CTE for Filtering and Paging
    ;WITH FilteredAdvances AS (
        SELECT 
            p.Amount,
            p.CreatedDate AS [Date],
            p.Status,
            p.GatewayReference AS ReferenceId,
            ISNULL(u.Name, 'System / Unknown') AS ResidentName,
            ISNULL(a.Name, 'General Wallet') AS UnitName,
            COUNT(*) OVER() as TotalCount
        FROM assoc.Payments p
        LEFT JOIN assoc.Users u ON p.UserId = u.UserId
        LEFT JOIN assoc.Assets a ON p.AssetId = a.AssetId
        WHERE p.TenantId = @TenantId
          AND p.InvoiceId IS NULL -- Top-ups / Advances
          AND (@AssociationId IS NULL OR p.AssociationId = @AssociationId)
          AND (@UserId IS NULL OR p.UserId = @UserId)
          AND (@AssetId IS NULL OR p.AssetId = @AssetId)
          AND (
               (@Status IS NULL AND p.Status IN ('Paid', 'Completed')) -- Default Filter
               OR (@Status IS NOT NULL AND p.Status = @Status) -- Specific Filter
          )
          AND (@StartDate IS NULL OR p.CreatedDate >= @StartDate)
          AND (@EndDate IS NULL OR p.CreatedDate <= @EndDate)
          AND (@SearchTerm IS NULL 
               OR u.Name LIKE '%' + @SearchTerm + '%' 
               OR a.Name LIKE '%' + @SearchTerm + '%'
               OR p.GatewayReference LIKE '%' + @SearchTerm + '%'
          )
    )
    SELECT 
        * 
    FROM FilteredAdvances
    ORDER BY 
        CASE WHEN @SortDirection = 'ASC' THEN
            CASE 
                WHEN @SortColumn = 'ResidentName' THEN ResidentName
                WHEN @SortColumn = 'UnitName' THEN UnitName
                WHEN @SortColumn = 'Status' THEN Status
                WHEN @SortColumn = 'ReferenceId' THEN ReferenceId
            END
        END ASC,
        CASE WHEN @SortDirection = 'DESC' THEN
            CASE 
                WHEN @SortColumn = 'ResidentName' THEN ResidentName
                WHEN @SortColumn = 'UnitName' THEN UnitName
                WHEN @SortColumn = 'Status' THEN Status
                WHEN @SortColumn = 'ReferenceId' THEN ReferenceId
            END
        END DESC,
        CASE WHEN @SortDirection = 'ASC' THEN
            CASE 
                WHEN @SortColumn = 'Amount' THEN Amount
                WHEN @SortColumn = 'Date' THEN CAST([Date] AS SQL_VARIANT)
            END
        END ASC,
        CASE WHEN @SortDirection = 'DESC' THEN
            CASE 
                WHEN @SortColumn = 'Amount' THEN Amount
                WHEN @SortColumn = 'Date' THEN CAST([Date] AS SQL_VARIANT)
            END
        END DESC
    OFFSET @Offset ROWS
    FETCH NEXT @PageSize ROWS ONLY;
END;