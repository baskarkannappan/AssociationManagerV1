-- Script0067_FixAdvanceProcedures.sql
-- Fixes for wallet balances and advance payment visibility.

-- 1. Fix Status filter in Advances History
CREATE OR ALTER PROCEDURE assoc.sp_Payments_GetAdvances
    @AssociationId INT,
    @TenantId INT,
    @UserId INT = NULL,
    @AssetId INT = NULL
AS
BEGIN
    SET NOCOUNT ON;

    SELECT 
        p.PaymentId,
        p.Amount,
        p.Currency,
        p.CreatedDate,
        p.Status,
        p.GatewayReference,
        p.Notes,
        a.Name as UnitName,
        u.Name as ResidentName,
        u.Email as ResidentEmail
    FROM assoc.Payments p
    LEFT JOIN assoc.Assets a ON p.AssetId = a.AssetId
    LEFT JOIN assoc.Users u ON p.UserId = u.UserId
    WHERE p.TenantId = @TenantId
      AND p.AssociationId = @AssociationId
      AND p.InvoiceId IS NULL  -- Only advances
      AND p.Status IN ('Paid', 'Completed') -- FIX: Include Completed
      AND (@UserId IS NULL OR p.UserId = @UserId)
      AND (@AssetId IS NULL OR p.AssetId = @AssetId)
    ORDER BY p.CreatedDate DESC;
END;
GO

-- 2. Fix Balance Calculation (Debit vs Credit) in Admin Summary
CREATE OR ALTER PROCEDURE assoc.sp_Finance_GetAssociationSummary
    @AssociationId INT,
    @TenantId INT
 AS
 BEGIN
     SET NOCOUNT ON;
 
     DECLARE @TotalOutstanding DECIMAL(18,2);
     DECLARE @TotalAdvanceCredits DECIMAL(18,2);
     DECLARE @UnitBalances TABLE (AssetId INT, Balance DECIMAL(18,2));
 
     INSERT INTO @UnitBalances (AssetId, Balance)
     SELECT AssetId, SUM(CASE WHEN Type = 'Debit' THEN Amount ELSE -Amount END) -- FIX: Signed Sum
     FROM assoc.Transactions
     WHERE TenantId = @TenantId AND AssociationId = @AssociationId
     GROUP BY AssetId;
 
     SELECT @TotalOutstanding = ISNULL(SUM(Balance), 0) FROM @UnitBalances WHERE Balance > 0;
     SELECT @TotalAdvanceCredits = ABS(ISNULL(SUM(Balance), 0)) FROM @UnitBalances WHERE Balance < 0;
 
     SELECT 
         @TotalOutstanding as TotalOutstanding,
         @TotalAdvanceCredits as TotalAdvanceCredits,
         (SELECT COUNT(*) FROM @UnitBalances WHERE Balance < 0) as UnitsWithCredit;
 END;
 GO

-- 3. Fix Balance Calculation in User List
CREATE OR ALTER PROCEDURE assoc.sp_Users_GetPaged
    @AssociationId INT = NULL,
    @TenantId INT = NULL,
    @SearchTerm NVARCHAR(255) = NULL,
    @Role NVARCHAR(50) = NULL,
    @PageNumber INT = 1,
    @PageSize INT = 10,
    @SortColumn NVARCHAR(50) = 'Name',
    @SortDirection NVARCHAR(10) = 'ASC'
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @Offset INT = (@PageNumber - 1) * @PageSize;
    IF @SortColumn NOT IN ('Name', 'Email', 'Role', 'CreatedDate', 'Balance') SET @SortColumn = 'Name';
    IF @SortDirection NOT IN ('ASC', 'DESC') SET @SortDirection = 'ASC';

    ;WITH UserAssets AS (
        SELECT u.UserId, MIN(o.AssetId) as AssetId  
        FROM assoc.Users u
        LEFT JOIN assoc.Persons p ON u.Email = p.Email
        LEFT JOIN assoc.Occupancy o ON p.PersonId = o.PersonId
        GROUP BY u.UserId
    ),
    AllMembers AS (
        SELECT 
            u.UserId, u.Name, u.Email, u.PictureUrl, u.IsActive, u.CreatedDate, 
            ISNULL(ua.Role, 'Resident') as Role,
            ISNULL(ua.AssociationId, o.AssociationId) as AssociationId,
            (SELECT ISNULL(SUM(CASE WHEN Type = 'Debit' THEN Amount ELSE -Amount END), 0) FROM assoc.Transactions t WHERE t.AssetId = o.AssetId) as Balance -- FIX: Signed Sum
        FROM assoc.Users u
        LEFT JOIN assoc.UserAssociations ua ON u.UserId = ua.UserId
        LEFT JOIN assoc.Persons p ON u.Email = p.Email
        LEFT JOIN assoc.Occupancy o ON p.PersonId = o.PersonId
    ),
    FilteredUsers AS (
        SELECT DISTINCT
            UserId, Name, Email, PictureUrl, IsActive, CreatedDate, Role, AssociationId, Balance,
            COUNT(*) OVER() as TotalCount
        FROM AllMembers
        WHERE (@AssociationId IS NULL OR @AssociationId = 0 OR AssociationId = @AssociationId)
        AND (@Role IS NULL OR Role = @Role)
        AND (@SearchTerm IS NULL OR Name LIKE '%' + @SearchTerm + '%' OR Email LIKE '%' + @SearchTerm + '%')
    )
    SELECT * FROM FilteredUsers
    ORDER BY 
        CASE WHEN @SortDirection = 'ASC' THEN
            CASE 
                WHEN @SortColumn = 'Name' THEN Name
                WHEN @SortColumn = 'Email' THEN Email
                WHEN @SortColumn = 'Role' THEN Role
            END
        END ASC,
        CASE WHEN @SortDirection = 'DESC' THEN
            CASE 
                WHEN @SortColumn = 'Name' THEN Name
                WHEN @SortColumn = 'Email' THEN Email
                WHEN @SortColumn = 'Role' THEN Role
            END
        END DESC,
        CASE WHEN @SortDirection = 'ASC' THEN
            CASE 
                WHEN @SortColumn = 'CreatedDate' THEN CAST(CreatedDate AS SQL_VARIANT)
                WHEN @SortColumn = 'Balance' THEN CAST(Balance AS SQL_VARIANT)
            END
        END ASC,
        CASE WHEN @SortDirection = 'DESC' THEN
            CASE 
                WHEN @SortColumn = 'CreatedDate' THEN CAST(CreatedDate AS SQL_VARIANT)
                WHEN @SortColumn = 'Balance' THEN CAST(Balance AS SQL_VARIANT)
            END
        END DESC
    OFFSET @Offset ROWS FETCH NEXT @PageSize ROWS ONLY;
END;
GO
