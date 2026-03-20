-- PERSONS
CREATE OR ALTER PROCEDURE assoc.sp_Persons_GetById @Id INT, @TenantId INT, @AssociationId INT AS 
BEGIN SELECT * FROM assoc.Persons WHERE PersonId = @Id AND TenantId = @TenantId AND AssociationId = @AssociationId; END
GO
CREATE OR ALTER PROCEDURE assoc.sp_Persons_GetAll @TenantId INT, @AssociationId INT AS 
BEGIN SELECT * FROM assoc.Persons WHERE TenantId = @TenantId AND AssociationId = @AssociationId AND IsActive = 1; END
GO
CREATE OR ALTER PROCEDURE assoc.sp_Persons_Create @TenantId INT, @AssociationId INT, @FirstName NVARCHAR(100), @LastName NVARCHAR(100), @Email NVARCHAR(255), @Phone NVARCHAR(50), @PhotoUrl NVARCHAR(MAX), @CreatedDate DATETIME, @IsActive BIT AS 
BEGIN INSERT INTO assoc.Persons (TenantId, AssociationId, FirstName, LastName, Email, Phone, PhotoUrl, CreatedDate, IsActive) OUTPUT INSERTED.PersonId VALUES (@TenantId, @AssociationId, @FirstName, @LastName, @Email, @Phone, @PhotoUrl, @CreatedDate, @IsActive); END
GO
CREATE OR ALTER PROCEDURE assoc.sp_Persons_Update @PersonId INT, @TenantId INT, @AssociationId INT, @FirstName NVARCHAR(100), @LastName NVARCHAR(100), @Email NVARCHAR(255), @Phone NVARCHAR(50), @PhotoUrl NVARCHAR(MAX), @IsActive BIT AS 
BEGIN UPDATE assoc.Persons SET FirstName = @FirstName, LastName = @LastName, Email = @Email, Phone = @Phone, PhotoUrl = @PhotoUrl, IsActive = @IsActive WHERE PersonId = @PersonId AND TenantId = @TenantId AND AssociationId = @AssociationId; END
GO
CREATE OR ALTER PROCEDURE assoc.sp_Persons_Delete @Id INT, @TenantId INT, @AssociationId INT AS 
BEGIN UPDATE assoc.Persons SET IsActive = 0 WHERE PersonId = @Id AND TenantId = @TenantId AND AssociationId = @AssociationId; END
GO

-- OCCUPANCY
CREATE OR ALTER PROCEDURE assoc.sp_Occupancy_GetByAssetId @AssetId INT, @TenantId INT, @AssociationId INT AS 
BEGIN SELECT * FROM assoc.Occupancy WHERE AssetId = @AssetId AND TenantId = @TenantId AND AssociationId = @AssociationId; END
GO
CREATE OR ALTER PROCEDURE assoc.sp_Occupancy_Create @AssetId INT, @PersonId INT, @TenantId INT, @AssociationId INT, @OccupancyType INT, @StartDate DATETIME, @EndDate DATETIME = NULL, @IsPrimaryContact BIT AS 
BEGIN INSERT INTO assoc.Occupancy (AssetId, PersonId, TenantId, AssociationId, OccupancyType, StartDate, EndDate, IsPrimaryContact) OUTPUT INSERTED.OccupancyId VALUES (@AssetId, @PersonId, @TenantId, @AssociationId, @OccupancyType, @StartDate, @EndDate, @IsPrimaryContact); END
GO
CREATE OR ALTER PROCEDURE assoc.sp_Occupancy_Delete @Id INT, @TenantId INT, @AssociationId INT AS 
BEGIN DELETE FROM assoc.Occupancy WHERE OccupancyId = @Id AND TenantId = @TenantId AND AssociationId = @AssociationId; END
GO
CREATE OR ALTER PROCEDURE assoc.sp_Occupancy_GetByUserId @UserId INT, @TenantId INT, @AssociationId INT AS 
BEGIN
    SELECT o.* FROM assoc.Occupancy o
    INNER JOIN assoc.Persons p ON o.PersonId = p.PersonId
    INNER JOIN corp.Users u ON p.Email = u.Email
    WHERE u.UserId = @UserId AND o.TenantId = @TenantId AND o.AssociationId = @AssociationId;
END
GO

-- ASSETS
CREATE OR ALTER PROCEDURE assoc.sp_Assets_GetById @Id INT, @TenantId INT, @AssociationId INT AS 
BEGIN SELECT * FROM assoc.Assets WHERE AssetId = @Id AND TenantId = @TenantId AND AssociationId = @AssociationId; END
GO
CREATE OR ALTER PROCEDURE assoc.sp_Assets_GetByParentId @ParentId INT = NULL, @TenantId INT, @AssociationId INT AS 
BEGIN
    IF @ParentId IS NULL
        SELECT * FROM assoc.Assets WHERE TenantId = @TenantId AND AssociationId = @AssociationId AND ParentId IS NULL;
    ELSE
        SELECT * FROM assoc.Assets WHERE TenantId = @TenantId AND AssociationId = @AssociationId AND ParentId = @ParentId;
END
GO
CREATE OR ALTER PROCEDURE assoc.sp_Assets_GetHierarchy @TenantId INT, @AssociationId INT AS 
BEGIN SELECT * FROM assoc.Assets WHERE TenantId = @TenantId AND AssociationId = @AssociationId AND IsActive = 1 ORDER BY ParentId, AssetType; END
GO
CREATE OR ALTER PROCEDURE assoc.sp_Assets_Create @ParentId INT = NULL, @TenantId INT, @AssociationId INT, @Name NVARCHAR(255), @Description NVARCHAR(MAX), @AssetType INT, @MetadataJson NVARCHAR(MAX), @CreatedDate DATETIME, @CreatedBy NVARCHAR(255), @IsActive BIT AS 
BEGIN INSERT INTO assoc.Assets (ParentId, TenantId, AssociationId, Name, Description, AssetType, MetadataJson, CreatedDate, CreatedBy, IsActive) OUTPUT INSERTED.AssetId VALUES (@ParentId, @TenantId, @AssociationId, @Name, @Description, @AssetType, @MetadataJson, @CreatedDate, @CreatedBy, @IsActive); END
GO
CREATE OR ALTER PROCEDURE assoc.sp_Assets_Update @AssetId INT, @TenantId INT, @AssociationId INT, @ParentId INT = NULL, @Name NVARCHAR(255), @Description NVARCHAR(MAX), @AssetType INT, @MetadataJson NVARCHAR(MAX), @IsActive BIT AS 
BEGIN UPDATE assoc.Assets SET ParentId = @ParentId, Name = @Name, Description = @Description, AssetType = @AssetType, MetadataJson = @MetadataJson, IsActive = @IsActive WHERE AssetId = @AssetId AND TenantId = @TenantId AND AssociationId = @AssociationId; END
GO
CREATE OR ALTER PROCEDURE assoc.sp_Assets_Delete @Id INT, @TenantId INT, @AssociationId INT AS 
BEGIN UPDATE assoc.Assets SET IsActive = 0 WHERE AssetId = @Id AND TenantId = @TenantId AND AssociationId = @AssociationId; END
GO
