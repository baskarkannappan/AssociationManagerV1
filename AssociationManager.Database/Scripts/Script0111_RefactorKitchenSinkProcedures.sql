-- Script0111_RefactorKitchenSinkProcedures.sql
-- Refactors complex 'OR' procedures into unionized queries for better execution plans.

-- 1. Refactor sp_Users_GetByAssociationId_Complex
IF EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID('corp.sp_Users_GetByAssociationId_Complex') AND type in (N'P', N'PC'))
BEGIN
    EXEC('ALTER PROCEDURE corp.sp_Users_GetByAssociationId_Complex
    @AssociationId INT
AS
BEGIN
    SET NOCOUNT ON;

    -- Branch 1: Directly assigned users
    SELECT u.*
    FROM corp.Users u
    WHERE u.AssociationId = @AssociationId

    UNION

    -- Branch 2: Residents via Occupancy
    -- Note: Uses JOIN instead of LEFT JOIN/OR to force index usage
    SELECT u.*
    FROM corp.Users u
    INNER JOIN assoc.Persons p ON u.Email = p.Email
    INNER JOIN assoc.Occupancy o ON p.PersonId = o.PersonId
    WHERE o.AssociationId = @AssociationId

    UNION

    -- Branch 3: Admins via Tenant association
    SELECT u.*
    FROM corp.Users u
    INNER JOIN corp.UserAssociations ua ON u.TenantId = ua.TenantId
    WHERE ua.Role IN (''SystemAdmin'', ''AssociationAdmin'') 
      AND u.TenantId = (SELECT TOP 1 TenantId FROM corp.Associations WHERE AssociationId = @AssociationId)

    ORDER BY Name;
END')
END
GO

-- 2. Optimize sp_Invoices_GetPaged with Recompile option to prevent parameter sniffing
IF EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID('assoc.sp_Invoices_GetPaged') AND type in (N'P', N'PC'))
BEGIN
    EXEC('ALTER PROCEDURE assoc.sp_Invoices_GetPaged
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
    @SortColumn NVARCHAR(50) = ''CreatedDate'',
    @SortDirection NVARCHAR(10) = ''DESC'',
    @IncludeDraft BIT = 0
AS
BEGIN
    SET NOCOUNT ON;
    
    DECLARE @Offset INT = (@PageNumber - 1) * @PageSize;
    
    IF @SortColumn NOT IN (''Title'', ''Amount'', ''DueDate'', ''Status'', ''CreatedDate'', ''AssetName'')
        SET @SortColumn = ''CreatedDate'';
    
    IF @SortDirection NOT IN (''ASC'', ''DESC'')
        SET @SortDirection = ''DESC'';

    ;WITH FilteredInvoices AS (
        SELECT 
            i.*,
            a.Name AS AssetName,
            CAST(COUNT(*) OVER() AS INT) as TotalCount,
            CAST(SUM(CASE WHEN LTRIM(RTRIM(i.Status)) IN (''Unpaid'', ''unpaid'', ''Partial'', ''partial'') THEN i.Amount ELSE 0 END) OVER() AS DECIMAL(18,2)) as TotalUnpaid
        FROM assoc.Invoices i
        LEFT JOIN assoc.Assets a ON i.AssetId = a.AssetId
        WHERE i.TenantId = @TenantId
        AND (@AssociationId IS NULL OR i.AssociationId = @AssociationId)
        AND (@AssetId IS NULL OR i.AssetId = @AssetId)
        AND (@AssetIds IS NULL OR i.AssetId IN (SELECT CAST(value AS INT) FROM STRING_SPLIT(@AssetIds, '','')))
        AND (@Status IS NULL OR i.Status = @Status)
        AND (@IncludeDraft = 1 OR i.Status != ''Draft'')
        AND (@SearchTerm IS NULL OR i.Title LIKE ''%'' + @SearchTerm + ''%'' OR a.Name LIKE ''%'' + @SearchTerm + ''%'')
        AND (@StartDate IS NULL OR i.CreatedDate >= @StartDate)
        AND (@EndDate IS NULL OR i.CreatedDate <= @EndDate)
    )
    SELECT 
        * 
    FROM FilteredInvoices
    ORDER BY 
        CASE WHEN @SortDirection = ''ASC'' THEN
            CASE 
                WHEN @SortColumn = ''Title'' THEN Title
                WHEN @SortColumn = ''Status'' THEN Status
                WHEN @SortColumn = ''AssetName'' THEN AssetName
            END
        END ASC,
        CASE WHEN @SortDirection = ''DESC'' THEN
            CASE 
                WHEN @SortColumn = ''Title'' THEN Title
                WHEN @SortColumn = ''Status'' THEN Status
                WHEN @SortColumn = ''AssetName'' THEN AssetName
            END
        END DESC,
        CASE WHEN @SortDirection = ''ASC'' THEN
            CASE 
                WHEN @SortColumn = ''Amount'' THEN Amount
                WHEN @SortColumn = ''DueDate'' THEN CAST(DueDate AS SQL_VARIANT)
                WHEN @SortColumn = ''CreatedDate'' THEN CAST(CreatedDate AS SQL_VARIANT)
            END
        END ASC,
        CASE WHEN @SortDirection = ''DESC'' THEN
            CASE 
                WHEN @SortColumn = ''Amount'' THEN Amount
                WHEN @SortColumn = ''DueDate'' THEN CAST(DueDate AS SQL_VARIANT)
                WHEN @SortColumn = ''CreatedDate'' THEN CAST(CreatedDate AS SQL_VARIANT)
            END
        END DESC
    OFFSET @Offset ROWS
    FETCH NEXT @PageSize ROWS ONLY
    OPTION (RECOMPILE); -- Solve parameter sniffing issues for optional filters
END')
END
GO
