-- RELAX TENANT FILTERS IN ASSOC SCHEMA
-- This ensures that residents (who may have TenantId=0 in their initial tokens) can access their data correctly.

PRINT 'Updating assoc.sp_Assets_GetHierarchy...'
GO
CREATE OR ALTER PROCEDURE assoc.sp_Assets_GetHierarchy @TenantId INT, @AssociationId INT AS 
BEGIN 
    SELECT * FROM assoc.Assets 
    WHERE AssociationId = @AssociationId AND IsActive = 1 
    ORDER BY ParentId, AssetType; 
END
GO

PRINT 'Updating assoc.sp_Occupancy_GetByUserId...'
GO
CREATE OR ALTER PROCEDURE assoc.sp_Occupancy_GetByUserId @UserId INT, @TenantId INT, @AssociationId INT AS 
BEGIN
    SELECT o.* FROM assoc.Occupancy o
    INNER JOIN assoc.Persons p ON o.PersonId = p.PersonId
    INNER JOIN assoc.Users u ON p.Email = u.Email
    WHERE u.UserId = @UserId AND o.AssociationId = @AssociationId;
END
GO

PRINT 'Updating assoc.sp_Occupancy_GetByAssetId...'
GO
CREATE OR ALTER PROCEDURE assoc.sp_Occupancy_GetByAssetId @AssetId INT, @TenantId INT, @AssociationId INT AS 
BEGIN SELECT * FROM assoc.Occupancy WHERE AssetId = @AssetId AND AssociationId = @AssociationId; END
GO

PRINT 'Updating assoc.sp_Broadcasts_GetAll...'
GO
CREATE OR ALTER PROCEDURE assoc.sp_Broadcasts_GetAll @TenantId INT, @AssociationId INT AS 
BEGIN
    SELECT b.*, u.Name as AuthorName, a.Name as AssetName
    FROM assoc.Broadcasts b 
    LEFT JOIN assoc.Users u ON b.CreatedBy = u.UserId
    LEFT JOIN assoc.Assets a ON b.AssetId = a.AssetId
    WHERE b.AssociationId = @AssociationId
    ORDER BY b.IsPinned DESC, b.CreatedDate DESC;
END
GO

PRINT 'Updating assoc.sp_Broadcasts_GetByAssetId...'
GO
CREATE OR ALTER PROCEDURE assoc.sp_Broadcasts_GetByAssetId @AssetId INT, @TenantId INT, @AssociationId INT AS 
BEGIN
    SELECT b.*, u.Name as AuthorName, a.Name as AssetName
    FROM assoc.Broadcasts b 
    LEFT JOIN assoc.Users u ON b.CreatedBy = u.UserId
    LEFT JOIN assoc.Assets a ON b.AssetId = a.AssetId
    WHERE b.AssociationId = @AssociationId AND (b.AssetId = @AssetId OR b.AssetId IS NULL)
    ORDER BY b.IsPinned DESC, b.CreatedDate DESC;
END
GO

PRINT 'Updating assoc.sp_Broadcasts_GetById...'
GO
CREATE OR ALTER PROCEDURE assoc.sp_Broadcasts_GetById @Id INT, @TenantId INT, @AssociationId INT AS 
BEGIN
    SELECT b.*, u.Name as AuthorName, a.Name as AssetName
    FROM assoc.Broadcasts b 
    LEFT JOIN assoc.Users u ON b.CreatedBy = u.UserId
    LEFT JOIN assoc.Assets a ON b.AssetId = a.AssetId
    WHERE b.BroadcastId = @Id AND b.AssociationId = @AssociationId;
END
GO

PRINT 'Updating assoc.sp_Persons_GetAll...'
GO
CREATE OR ALTER PROCEDURE assoc.sp_Persons_GetAll @TenantId INT, @AssociationId INT AS 
BEGIN SELECT * FROM assoc.Persons WHERE AssociationId = @AssociationId AND IsActive = 1; END
GO

PRINT 'Updating assoc.sp_Persons_GetById...'
GO
CREATE OR ALTER PROCEDURE assoc.sp_Persons_GetById @Id INT, @TenantId INT, @AssociationId INT AS 
BEGIN SELECT * FROM assoc.Persons WHERE PersonId = @Id AND AssociationId = @AssociationId; END
GO

PRINT 'Updating assoc.sp_Vehicles_GetByAssetId...'
GO
CREATE OR ALTER PROCEDURE assoc.sp_Vehicles_GetByAssetId @AssetId INT, @TenantId INT, @AssociationId INT AS 
BEGIN SELECT * FROM assoc.Vehicles WHERE AssetId = @AssetId AND AssociationId = @AssociationId; END
GO

PRINT 'Updating assoc.sp_Pets_GetByAssetId...'
GO
CREATE OR ALTER PROCEDURE assoc.sp_Pets_GetByAssetId @AssetId INT, @TenantId INT, @AssociationId INT AS 
BEGIN SELECT * FROM assoc.Pets WHERE AssetId = @AssetId AND AssociationId = @AssociationId; END
GO

PRINT 'Migration Script 0041 Complete.'
GO
