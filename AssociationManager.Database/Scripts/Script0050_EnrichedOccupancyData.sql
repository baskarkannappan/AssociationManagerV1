-- Script0050_EnrichedOccupancyData.sql
-- Relax TenantId filtering and enrich occupancy results with person details (Name/Email)

PRINT 'Enriching Occupancy procedures with Person details...'
GO

CREATE OR ALTER PROCEDURE assoc.sp_Occupancy_GetByAssetId 
    @AssetId INT, 
    @TenantId INT, 
    @AssociationId INT 
AS 
BEGIN 
    SELECT o.*, 
           (p.FirstName + ' ' + p.LastName) as PersonName, 
           p.Email as Email 
    FROM assoc.Occupancy o
    JOIN assoc.Persons p ON o.PersonId = p.PersonId
    WHERE o.AssetId = @AssetId AND o.AssociationId = @AssociationId; 
END
GO

CREATE OR ALTER PROCEDURE assoc.sp_Occupancy_GetById 
    @Id INT, 
    @TenantId INT, 
    @AssociationId INT 
AS 
BEGIN 
    SELECT o.*, 
           (p.FirstName + ' ' + p.LastName) as PersonName, 
           p.Email as Email 
    FROM assoc.Occupancy o
    JOIN assoc.Persons p ON o.PersonId = p.PersonId
    WHERE o.OccupancyId = @Id AND o.AssociationId = @AssociationId; 
END
GO

CREATE OR ALTER PROCEDURE assoc.sp_Occupancy_GetByUserId 
    @UserId INT, 
    @TenantId INT, 
    @AssociationId INT 
AS 
BEGIN
    SELECT o.*,
           (p.FirstName + ' ' + p.LastName) as PersonName, 
           p.Email as Email 
    FROM assoc.Occupancy o
    INNER JOIN assoc.Persons p ON o.PersonId = p.PersonId
    INNER JOIN corp.Users u ON p.Email = u.Email
    WHERE u.UserId = @UserId AND o.AssociationId = @AssociationId;
END
GO

PRINT 'Script 0050 Complete.'
GO
