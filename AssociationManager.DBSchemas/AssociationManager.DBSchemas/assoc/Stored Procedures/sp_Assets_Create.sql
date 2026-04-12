CREATE PROCEDURE assoc.sp_Assets_Create
    @ParentId INT = NULL,
    @TenantId INT,
    @AssociationId INT,
    @Name NVARCHAR(255),
    @Description NVARCHAR(MAX),
    @AssetType INT,
    @MetadataJson NVARCHAR(MAX),
    @CreatedDate DATETIME,
    @CreatedBy NVARCHAR(255),
    @IsActive BIT
AS
BEGIN
    SET NOCOUNT ON;

    -- IRONCLAD SAFETY GUARD: Ensure ParentId belongs to the same association.
    -- If it doesn't, we force the new asset to be a 'Root' building for this association.
    IF @ParentId IS NOT NULL AND @ParentId != 0
    BEGIN
        IF NOT EXISTS (SELECT 1 FROM [assoc].[Assets] WHERE [AssetId] = @ParentId AND [AssociationId] = @AssociationId)
        BEGIN
            SET @ParentId = NULL;
        END
    END

    INSERT INTO assoc.Assets (
        ParentId, 
        TenantId, 
        AssociationId, 
        Name, 
        Description, 
        AssetType, 
        MetadataJson, 
        CreatedDate, 
        CreatedBy, 
        IsActive
    )
    OUTPUT INSERTED.AssetId
    VALUES (
        @ParentId, 
        @TenantId, 
        @AssociationId, 
        @Name, 
        @Description, 
        @AssetType, 
        @MetadataJson, 
        @CreatedDate, 
        @CreatedBy, 
        @IsActive
    );
END