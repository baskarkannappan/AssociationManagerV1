-- Fix sp_Assets_Create parameter mismatch and type consistency
CREATE OR ALTER PROCEDURE sp_Assets_Create
    @ParentId INT = NULL,
    @TenantId INT,
    @AssociationId INT,
    @Name NVARCHAR(255),
    @Description NVARCHAR(MAX),
    @AssetType INT,
    @MetadataJson NVARCHAR(MAX),
    @CreatedDate DATETIME,
    @CreatedBy INT, -- Changed from NVARCHAR(255) to match table schema
    @IsActive BIT
AS
BEGIN
    INSERT INTO Assets (ParentId, TenantId, AssociationId, Name, Description, AssetType, MetadataJson, CreatedDate, CreatedBy, IsActive)
    OUTPUT INSERTED.AssetId
    VALUES (@ParentId, @TenantId, @AssociationId, @Name, @Description, @AssetType, @MetadataJson, @CreatedDate, @CreatedBy, @IsActive);
END
GO
