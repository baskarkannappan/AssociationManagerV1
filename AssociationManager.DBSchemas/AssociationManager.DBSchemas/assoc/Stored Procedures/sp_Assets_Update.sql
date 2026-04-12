CREATE PROCEDURE assoc.sp_Assets_Update
    @AssetId INT,
    @TenantId INT,
    @AssociationId INT,
    @ParentId INT = NULL,
    @Name NVARCHAR(255),
    @Description NVARCHAR(MAX),
    @AssetType INT,
    @MetadataJson NVARCHAR(MAX),
    @IsActive BIT
AS
BEGIN
    SET NOCOUNT ON;

    -- IRONCLAD SAFETY GUARD: Prevent moving asset to a parent in a different association.
    IF @ParentId IS NOT NULL AND @ParentId != 0
    BEGIN
        IF NOT EXISTS (SELECT 1 FROM [assoc].[Assets] WHERE [AssetId] = @ParentId AND [AssociationId] = @AssociationId)
        BEGIN
            -- If cross-association move is attempted, keep it as root in its OWN association.
            SET @ParentId = NULL;
        END
    END

    UPDATE assoc.Assets
    SET ParentId = @ParentId,
        Name = @Name,
        Description = @Description,
        AssetType = @AssetType,
        MetadataJson = @MetadataJson,
        IsActive = @IsActive
    WHERE AssetId = @AssetId 
      AND TenantId = @TenantId 
      AND AssociationId = @AssociationId;

    -- Cascade Deactivation
    IF @IsActive = 0
    BEGIN
        WITH AssetHierarchy AS (
            SELECT AssetId 
            FROM assoc.Assets 
            WHERE ParentId = @AssetId 
              AND TenantId = @TenantId 
              AND AssociationId = @AssociationId
            UNION ALL
            SELECT a.AssetId 
            FROM assoc.Assets a
            INNER JOIN AssetHierarchy h ON a.ParentId = h.AssetId
            WHERE a.TenantId = @TenantId 
              AND a.AssociationId = @AssociationId
        )
        UPDATE a
        SET a.IsActive = 0
        FROM assoc.Assets a
        INNER JOIN AssetHierarchy h ON a.AssetId = h.AssetId;
    END
END