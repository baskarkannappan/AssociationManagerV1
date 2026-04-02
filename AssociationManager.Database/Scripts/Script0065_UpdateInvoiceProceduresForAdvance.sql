-- Script0065_UpdateInvoiceProceduresForAdvance.sql
-- Updates invoice procedures to include IsAdvancePaid flag

-- 1. Update GetPaged
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
            CAST(CASE WHEN EXISTS (SELECT 1 FROM assoc.Payments p WHERE p.InvoiceId = i.InvoiceId AND p.Notes LIKE '%Advance%') THEN 1 ELSE 0 END AS BIT) AS IsAdvancePaid,
            CAST(COUNT(*) OVER() AS INT) as TotalCount,
            CAST(SUM(CASE WHEN i.Status = 'Unpaid' THEN i.Amount ELSE 0 END) OVER() AS DECIMAL(18,2)) as TotalUnpaid
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

-- 2. Update GetByAssetId
CREATE OR ALTER PROCEDURE assoc.sp_Invoices_GetByAssetId
    @AssetId INT,
    @TenantId INT,
    @AssociationId INT
AS
BEGIN
    SELECT i.*, 
           a.Name AS AssetName,
           CAST(CASE WHEN EXISTS (SELECT 1 FROM assoc.Payments p WHERE p.InvoiceId = i.InvoiceId AND p.Notes LIKE '%Advance%') THEN 1 ELSE 0 END AS BIT) AS IsAdvancePaid
    FROM assoc.Invoices i
    LEFT JOIN assoc.Assets a ON i.AssetId = a.AssetId
    WHERE i.AssetId = @AssetId AND i.TenantId = @TenantId AND i.AssociationId = @AssociationId
    ORDER BY i.DueDate DESC;
END;
GO

-- 3. Update GetById
CREATE OR ALTER PROCEDURE assoc.sp_Invoices_GetById
    @Id INT,
    @TenantId INT,
    @AssociationId INT
AS
BEGIN
    SELECT i.*, 
           a.Name AS AssetName,
           CAST(CASE WHEN EXISTS (SELECT 1 FROM assoc.Payments p WHERE p.InvoiceId = i.InvoiceId AND p.Notes LIKE '%Advance%') THEN 1 ELSE 0 END AS BIT) AS IsAdvancePaid
    FROM assoc.Invoices i
    LEFT JOIN assoc.Assets a ON i.AssetId = a.AssetId
    WHERE i.InvoiceId = @Id AND i.TenantId = @TenantId AND i.AssociationId = @AssociationId;
END;
GO

-- 4. Update GetAll
CREATE OR ALTER PROCEDURE assoc.sp_Invoices_GetAll
    @TenantId INT,
    @AssociationId INT
AS
BEGIN
    SELECT i.*, 
           a.Name AS AssetName,
           CAST(CASE WHEN EXISTS (SELECT 1 FROM assoc.Payments p WHERE p.InvoiceId = i.InvoiceId AND p.Notes LIKE '%Advance%') THEN 1 ELSE 0 END AS BIT) AS IsAdvancePaid
    FROM assoc.Invoices i
    LEFT JOIN assoc.Assets a ON i.AssetId = a.AssetId
    WHERE i.TenantId = @TenantId AND i.AssociationId = @AssociationId
    ORDER BY i.CreatedDate DESC;
END;
GO
