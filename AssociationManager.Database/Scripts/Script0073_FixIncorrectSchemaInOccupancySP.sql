-- Script0073_FixAndEnrichOccupancyStoredProcedures.sql
-- 1. Fix the incorrect schema reference (corp.Assets -> assoc.Assets) 
-- 2. Enrich all occupancy procedures with names for consistent UI display

PRINT 'Updating assoc.sp_Occupancy_GetByUserId with correct schema and enrichment...'
GO
CREATE OR ALTER PROCEDURE assoc.sp_Occupancy_GetByUserId
    @UserId INT,
    @TenantId INT,
    @AssociationId INT
AS
BEGIN
    SELECT o.*,
           (p.FirstName + ' ' + p.LastName) as PersonName,
           p.Email as Email,
           a.Name as AssetName
    FROM assoc.Occupancy o
    INNER JOIN assoc.Persons p ON o.PersonId = p.PersonId
    INNER JOIN assoc.Users u ON p.Email = u.Email
    LEFT JOIN assoc.Assets a ON o.AssetId = a.AssetId
    WHERE u.UserId = @UserId AND o.AssociationId = @AssociationId;
END
GO

PRINT 'Updating assoc.sp_Occupancy_GetByAssetId with enrichment...'
GO
CREATE OR ALTER PROCEDURE assoc.sp_Occupancy_GetByAssetId
    @AssetId INT,
    @TenantId INT,
    @AssociationId INT
AS
BEGIN
    SELECT o.*,
           (p.FirstName + ' ' + p.LastName) as PersonName,
           p.Email as Email,
           a.Name as AssetName
    FROM assoc.Occupancy o
    INNER JOIN assoc.Persons p ON o.PersonId = p.PersonId
    LEFT JOIN assoc.Assets a ON o.AssetId = a.AssetId
    WHERE o.AssetId = @AssetId AND o.AssociationId = @AssociationId;
END
GO

PRINT 'Updating assoc.sp_Occupancy_GetById with enrichment...'
GO
CREATE OR ALTER PROCEDURE assoc.sp_Occupancy_GetById
    @Id INT,
    @TenantId INT,
    @AssociationId INT
AS
BEGIN
    SELECT o.*,
           (p.FirstName + ' ' + p.LastName) as PersonName,
           p.Email as Email,
           a.Name as AssetName
    FROM assoc.Occupancy o
    INNER JOIN assoc.Persons p ON o.PersonId = p.PersonId
    LEFT JOIN assoc.Assets a ON o.AssetId = a.AssetId
    WHERE o.OccupancyId = @Id AND o.AssociationId = @AssociationId;
END
GO

PRINT 'Script 0073 Complete.'
GO
