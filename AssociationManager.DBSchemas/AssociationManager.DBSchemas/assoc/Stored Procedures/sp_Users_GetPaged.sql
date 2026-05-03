CREATE   PROCEDURE assoc.sp_Users_GetPaged
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
    
    IF @SortColumn NOT IN ('Name', 'Email', 'Role', 'CreatedDate', 'Balance')
        SET @SortColumn = 'Name';
    
    IF @SortDirection NOT IN ('ASC', 'DESC')
        SET @SortDirection = 'ASC';

    -- 1. Identify all unique members and their highest-priority role
    ;WITH MemberRoles AS (
        -- Staff Mappings
        SELECT 
            ua.UserId, 
            ua.Role, 
            ua.AssociationId,
            CASE 
                WHEN ua.Role = 'AssociationAdmin' THEN 1
                WHEN ua.Role = 'FinanceManager' THEN 2
                WHEN ua.Role = 'CommitteeMember' THEN 3
                WHEN ua.Role = 'Staff' THEN 4
                ELSE 5 
            END as RolePriority
        FROM assoc.UserAssociations ua
        WHERE (@AssociationId IS NULL OR @AssociationId = 0 OR ua.AssociationId = @AssociationId)

        UNION ALL

        -- Resident Mappings (via Occupancy)
        SELECT 
            u.UserId, 
            'Resident' as Role, 
            o.AssociationId,
            6 as RolePriority -- Lowest priority
        FROM assoc.Users u
        INNER JOIN assoc.Persons p ON u.Email = p.Email
        INNER JOIN assoc.Occupancy o ON p.PersonId = o.PersonId
        WHERE (@AssociationId IS NULL OR @AssociationId = 0 OR o.AssociationId = @AssociationId)

        UNION ALL

        -- Fallback Global Admins
        SELECT 
            u.UserId, 
            ua.Role, 
            ua.TenantId as AssociationId,
            1 as RolePriority
        FROM corp.Users u
        INNER JOIN corp.UserAssociations ua ON u.UserId = ua.UserId
        WHERE (@AssociationId IS NULL OR @AssociationId = 0 OR ua.TenantId = @AssociationId)
        AND u.Email NOT IN (SELECT Email FROM assoc.Users)
    ),
    UniqueMembers AS (
        -- Pick the best role per User/Association combo
        SELECT 
            UserId, 
            AssociationId,
            Role,
            ROW_NUMBER() OVER(PARTITION BY UserId, AssociationId ORDER BY RolePriority ASC) as RoleRank
        FROM MemberRoles
    ),
    MemberBalances AS (
        -- Calculate total balance for residents across all their units in this association
        -- (Only applies to residents, but we join globally)
        SELECT 
            u.UserId,
            @AssociationId as AssociationId,
            ISNULL(SUM(CASE WHEN t.Type = 'Debit' THEN t.Amount ELSE -t.Amount END), 0) as Balance
        FROM assoc.Users u
        -- Get all persons for this user email
        INNER JOIN assoc.Persons p ON u.Email = p.Email
        -- Get all occupancy for those persons
        INNER JOIN assoc.Occupancy o ON p.PersonId = o.PersonId
        -- Join transactions for those assets
        LEFT JOIN assoc.Transactions t ON o.AssetId = t.AssetId AND t.AssociationId = o.AssociationId
        WHERE (@AssociationId IS NULL OR @AssociationId = 0 OR o.AssociationId = @AssociationId)
        GROUP BY u.UserId
    ),
    PagedMembers AS (
        SELECT 
            u.UserId, u.Name, u.Email, u.PictureUrl, u.IsActive, u.CreatedDate,
            um.Role,
            CAST(ISNULL(mb.Balance, 0) AS DECIMAL(18,2)) as Balance,
            CAST(COUNT(*) OVER() AS INT) as TotalCount
        FROM assoc.Users u
        INNER JOIN UniqueMembers um ON u.UserId = um.UserId AND um.RoleRank = 1
        LEFT JOIN MemberBalances mb ON u.UserId = mb.UserId
        WHERE (@AssociationId IS NULL OR @AssociationId = 0 OR um.AssociationId = @AssociationId)
        AND (@Role IS NULL OR um.Role = @Role)
        AND (@SearchTerm IS NULL OR u.Name LIKE '%' + @SearchTerm + '%' OR u.Email LIKE '%' + @SearchTerm + '%')
    )
    SELECT 
        * 
    FROM PagedMembers
    ORDER BY 
        CASE WHEN @SortDirection = 'ASC' AND @SortColumn = 'Name' THEN Name END ASC,
        CASE WHEN @SortDirection = 'DESC' AND @SortColumn = 'Name' THEN Name END DESC,
        CASE WHEN @SortDirection = 'ASC' AND @SortColumn = 'Email' THEN Email END ASC,
        CASE WHEN @SortDirection = 'DESC' AND @SortColumn = 'Email' THEN Email END DESC,
        CASE WHEN @SortDirection = 'ASC' AND @SortColumn = 'Role' THEN Role END ASC,
        CASE WHEN @SortDirection = 'DESC' AND @SortColumn = 'Role' THEN Role END DESC,
        CASE WHEN @SortDirection = 'ASC' AND @SortColumn = 'Balance' THEN Balance END ASC,
        CASE WHEN @SortDirection = 'DESC' AND @SortColumn = 'Balance' THEN Balance END DESC,
        CASE WHEN @SortDirection = 'ASC' AND @SortColumn = 'CreatedDate' THEN CreatedDate END ASC,
        CASE WHEN @SortDirection = 'DESC' AND @SortColumn = 'CreatedDate' THEN CreatedDate END DESC
    OFFSET @Offset ROWS
    FETCH NEXT @PageSize ROWS ONLY;
END;