-- Script0063_FixUserPaging_Final.sql
-- High-performance Server-Side Paging for Association Members (Users)
-- This script replaces any previous versions to ensure all Staff and Residents are visible.

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
    
    -- Calculate Offset
    DECLARE @Offset INT = (@PageNumber - 1) * @PageSize;
    
    -- Sorting Safety
    IF @SortColumn NOT IN ('Name', 'Email', 'Role', 'CreatedDate')
        SET @SortColumn = 'Name';
    
    IF @SortDirection NOT IN ('ASC', 'DESC')
        SET @SortDirection = 'ASC';

    -- CTE for Filtering and Paging
    ;WITH AllMembers AS (
        -- 1. Local Association Staff (mapped directly in the assoc schema)
        SELECT 
            u.UserId, u.Name, u.Email, u.PictureUrl, u.IsActive, u.CreatedDate, 
            ua.Role, ua.AssociationId
        FROM assoc.Users u
        INNER JOIN assoc.UserAssociations ua ON u.UserId = ua.UserId
        
        UNION
        
        -- 2. Residents (Inferred through Persons linked to Occupancy)
        SELECT DISTINCT
            u.UserId, u.Name, u.Email, u.PictureUrl, u.IsActive, u.CreatedDate,
            'Resident' as Role, o.AssociationId
        FROM assoc.Users u
        INNER JOIN assoc.Persons p ON u.Email = p.Email
        INNER JOIN assoc.Occupancy o ON p.PersonId = o.PersonId
        
        UNION
        
        -- 3. Fallback: Check Global System Staff (corp mappings)
        -- This covers cases where an admin was created globally but not yet provisioned locally
        SELECT 
            u.UserId, u.Name, u.Email, u.PictureUrl, u.IsActive, u.CreatedDate, 
            ua.Role, ua.TenantId as AssociationId
        FROM corp.Users u
        INNER JOIN corp.UserAssociations ua ON u.UserId = ua.UserId
        -- Only take from here if NOT already found in local assoc.Users
        WHERE u.Email NOT IN (SELECT Email FROM assoc.Users)
    ),
    FilteredUsers AS (
        SELECT 
            *,
            COUNT(*) OVER() as TotalCount
        FROM AllMembers
        -- Robust filter for AssociationId (matches passed parameter or ignore if 0/NULL)
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
            END
        END ASC,
        CASE WHEN @SortDirection = 'DESC' THEN
            CASE 
                WHEN @SortColumn = 'CreatedDate' THEN CAST(CreatedDate AS SQL_VARIANT)
            END
        END DESC
    OFFSET @Offset ROWS
    FETCH NEXT @PageSize ROWS ONLY;
END;