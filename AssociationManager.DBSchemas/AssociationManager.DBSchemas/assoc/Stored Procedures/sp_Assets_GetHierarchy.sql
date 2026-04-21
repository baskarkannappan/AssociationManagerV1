CREATE OR ALTER PROCEDURE assoc.sp_Assets_GetHierarchy 
    @TenantId INT, 
    @AssociationId INT,
    @ParentId INT = NULL,
    @UserId INT = NULL
AS 
BEGIN 
    SET NOCOUNT ON;

    -- If a UserId is provided, we filter by the user's accessibility (Recursive)
    -- This logic was present in the original procedure and I must preserve it.
    IF @UserId IS NOT NULL
    BEGIN
        WITH ResidentAssets AS (
            SELECT AssetId FROM assoc.Occupancies 
            WHERE UserId = @UserId AND TenantId = @TenantId AND (IsOwner = 1 OR IsOccupant = 1)
        ),
        HierarchyPath AS (
            SELECT a.* FROM assoc.Assets a
            JOIN ResidentAssets ra ON a.AssetId = ra.AssetId
            WHERE a.TenantId = @TenantId AND a.AssociationId = @AssociationId
            
            UNION ALL
            
            SELECT a.* FROM assoc.Assets a
            INNER JOIN HierarchyPath h ON a.AssetId = h.ParentId
            WHERE a.TenantId = @TenantId AND a.AssociationId = @AssociationId
        )
        SELECT DISTINCT * FROM HierarchyPath
        WHERE ( (@ParentId IS NULL AND ParentId IS NULL) OR (ParentId = @ParentId) )
        AND IsActive = 1
        ORDER BY AssetType, Name;
    END
    ELSE IF @ParentId IS NULL
    BEGIN
        -- ROOT Load: TOP 10000 safety for massive associations
        -- Return ONLY essential columns for the explorer tree to minimize payload size
        SELECT TOP 10000 AssetId, ParentId, TenantId, AssociationId, Name, AssetType, IsActive
        FROM assoc.Assets 
        WHERE TenantId = @TenantId 
        AND AssociationId = @AssociationId 
        AND ParentId IS NULL
        AND IsActive = 1 
        ORDER BY AssetType, Name;
    END
    ELSE
    BEGIN
        -- CHILD Load: Return children for a specific parent
        SELECT AssetId, ParentId, TenantId, AssociationId, Name, AssetType, IsActive
        FROM assoc.Assets 
        WHERE TenantId = @TenantId 
        AND AssociationId = @AssociationId 
        AND ParentId = @ParentId
        AND IsActive = 1
        ORDER BY AssetType, Name;
    END
END
GO