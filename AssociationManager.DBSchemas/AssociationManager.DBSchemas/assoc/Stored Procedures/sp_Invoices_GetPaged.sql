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
    @SortDirection NVARCHAR(10) = 'DESC',
    @IncludeDraft BIT = 0,
    @ReferenceId INT = NULL -- Keyset Pagination Support
AS
BEGIN
    SET NOCOUNT ON;
    
    DECLARE @Offset INT = (@PageNumber - 1) * @PageSize;
    
    IF @SortColumn NOT IN ('Title', 'Amount', 'DueDate', 'Status', 'CreatedDate', 'AssetName')
        SET @SortColumn = 'CreatedDate';
    
    IF @SortDirection NOT IN ('ASC', 'DESC')
        SET @SortDirection = 'DESC';

    -- Note: For 10M+ scaling, Keyset pagination is invoked if @ReferenceId is provided.
    -- If @ReferenceId is null, we fall back to OFFSET/FETCH (legacy support).

    ;WITH FilteredInvoices AS (
        SELECT 
            i.InvoiceId, i.TenantId, i.AssociationId, i.AssetId, i.BillingBatchId, i.Title, i.Description, 
            CASE WHEN i.Amount > ISNULL(li.TotalAmount, 0) THEN i.Amount ELSE ISNULL(li.TotalAmount, 0) END as Amount,
            i.DueDate, i.Status, i.CreatedDate,
            a.Name AS AssetName,
            CAST(COUNT(*) OVER() AS INT) as TotalCount,
            CAST(SUM(CASE WHEN i.Status NOT IN ('Paid', 'Cancelled', 'Void', 'Draft') 
                     THEN (CASE WHEN i.Amount > ISNULL(li.TotalAmount, 0) THEN i.Amount ELSE ISNULL(li.TotalAmount, 0) END) 
                     ELSE 0 END) OVER() AS DECIMAL(18,2)) as TotalUnpaid
        FROM assoc.Invoices i WITH (NOLOCK)
        LEFT JOIN assoc.Assets a WITH (NOLOCK) ON i.AssetId = a.AssetId
        OUTER APPLY (
            SELECT SUM(Amount) as TotalAmount 
            FROM assoc.InvoiceLineItems li WITH (NOLOCK)
            WHERE li.InvoiceId = i.InvoiceId
        ) li
        WHERE i.TenantId = @TenantId
        AND (@AssociationId IS NULL OR i.AssociationId = @AssociationId)
        AND (@AssetId IS NULL OR i.AssetId = @AssetId)
        AND (@AssetIds IS NULL OR i.AssetId IN (SELECT CAST(value AS INT) FROM STRING_SPLIT(@AssetIds, ',')))
        AND (@Status IS NULL OR i.Status = @Status)
        AND (@IncludeDraft = 1 OR i.Status NOT IN ('Draft', 'Error'))
        AND (@SearchTerm IS NULL OR i.Title LIKE '%' + @SearchTerm + '%' OR a.Name LIKE '%' + @SearchTerm + '%')
        AND (@StartDate IS NULL OR i.CreatedDate >= @StartDate)
        AND (@EndDate IS NULL OR i.CreatedDate <= @EndDate)
        AND (
            @ReferenceId IS NULL OR 
            (@SortDirection = 'DESC' AND i.InvoiceId < @ReferenceId) OR 
            (@SortDirection = 'ASC' AND i.InvoiceId > @ReferenceId)
        )
    )
    SELECT 
        * 
    FROM FilteredInvoices
    ORDER BY 
        -- ORDER BY logic preserved for sorting compatibility
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
    OFFSET (CASE WHEN @ReferenceId IS NOT NULL THEN 0 ELSE @Offset END) ROWS
    FETCH NEXT @PageSize ROWS ONLY
    OPTION (RECOMPILE); 
END
GO