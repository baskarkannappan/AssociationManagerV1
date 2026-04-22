-- Migration Script 0124: Fix Asset Hierarchy Resident Filtering logic and table names
-- Corrects typo in table name (Occupancy) and updates join logic to correctly link UserId to Assets.

CREATE   PROCEDURE assoc.sp_Assets_GetHierarchy 
    @TenantId INT, 
    @AssociationId INT,
    @ParentId INT = NULL,
    @UserId INT = NULL
AS 
BEGIN 
    SET NOCOUNT ON;

    -- If a UserId is provided, we filter by the user's accessibility (Recursive)
    IF @UserId IS NOT NULL
    BEGIN
        WITH ResidentAssets AS (
            -- Link UserId -> assoc.Users (Email) -> assoc.Persons (PersonId) -> assoc.Occupancy (AssetId)
            SELECT o.AssetId 
            FROM assoc.Occupancy o
            JOIN assoc.Persons p ON o.PersonId = p.PersonId
            JOIN assoc.Users u ON p.Email = u.Email
            WHERE u.UserId = @UserId 
            AND o.TenantId = @TenantId 
            AND o.AssociationId = @AssociationId
        ),
        HierarchyPath AS (
            -- Anchor: user's primary assets
            SELECT a.* FROM assoc.Assets a
            JOIN ResidentAssets ra ON a.AssetId = ra.AssetId
            WHERE a.TenantId = @TenantId AND a.AssociationId = @AssociationId
            
            UNION ALL
            
            -- Recursive: traverse UP to root
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
        -- ROOT Load
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
        -- CHILD Load
        SELECT AssetId, ParentId, TenantId, AssociationId, Name, AssetType, IsActive
        FROM assoc.Assets 
        WHERE TenantId = @TenantId 
        AND AssociationId = @AssociationId 
        AND ParentId = @ParentId
        AND IsActive = 1
        ORDER BY AssetType, Name;
    END
END