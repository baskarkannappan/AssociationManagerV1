-- Script0065_AdminFinanceMetrics.sql
-- Provides high-level visibility for admins into advance payments and unit balances.

-- 1. Create Summary Procedure for Admin Dashboard
CREATE OR ALTER PROCEDURE assoc.sp_Finance_GetAssociationSummary
    @AssociationId INT,
    @TenantId INT
AS
BEGIN
    SET NOCOUNT ON;

    -- Calculate Totals from the ledger
    DECLARE @TotalOutstanding DECIMAL(18,2);
    DECLARE @TotalAdvanceCredits DECIMAL(18,2);

    -- Intermediate table to hold unit balances
    DECLARE @UnitBalances TABLE (AssetId INT, Balance DECIMAL(18,2));

    INSERT INTO @UnitBalances (AssetId, Balance)
    SELECT AssetId, SUM(CASE WHEN Type = 'Debit' THEN Amount ELSE -Amount END)
    FROM assoc.Transactions
    WHERE TenantId = @TenantId AND AssociationId = @AssociationId
    GROUP BY AssetId;

    -- Total Outstanding (Sum of all positive balances)
    SELECT @TotalOutstanding = ISNULL(SUM(Balance), 0)
    FROM @UnitBalances
    WHERE Balance > 0;

    -- Total Advance Credits (Sum of all negative balances, absolute)
    SELECT @TotalAdvanceCredits = ABS(ISNULL(SUM(Balance), 0))
    FROM @UnitBalances
    WHERE Balance < 0;

    SELECT 
        @TotalOutstanding as TotalOutstanding,
        @TotalAdvanceCredits as TotalAdvanceCredits,
        (SELECT COUNT(*) FROM @UnitBalances WHERE Balance < 0) as UnitsWithCredit;
END;
GO

-- 2. Update Users Paged Procedure to include Balance
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
    
    -- Calculate Offset
    DECLARE @Offset INT = (@PageNumber - 1) * @PageSize;
    
    -- Sorting Safety
    IF @SortColumn NOT IN ('Name', 'Email', 'Role', 'CreatedDate', 'Balance')
        SET @SortColumn = 'Name';
    
    IF @SortDirection NOT IN ('ASC', 'DESC')
        SET @SortDirection = 'ASC';

    -- CTE for Filtering and Paging
    ;WITH UserAssets AS (
        -- Map users to assets where possible (Residents)
        SELECT 
            u.UserId,
            MIN(o.AssetId) as AssetId  -- Handle case where user has multiple units by picking one for summary
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
            (SELECT ISNULL(SUM(CASE WHEN Type = 'Debit' THEN Amount ELSE -Amount END), 0) FROM assoc.Transactions t WHERE t.AssetId = o.AssetId) as Balance
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
    SELECT 
        * 
    FROM FilteredUsers
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
    OFFSET @Offset ROWS
    FETCH NEXT @PageSize ROWS ONLY;
END;
GO
