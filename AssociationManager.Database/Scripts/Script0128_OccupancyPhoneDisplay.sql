-- Script0128_OccupancyPhoneDisplay.sql
-- Author: Antigravity
-- Purpose: Update occupancy stored procedures to return the Phone column for display in the Assets section.

PRINT 'Updating assoc.sp_Occupancy_GetByAssetId...'
GO
ALTER PROCEDURE assoc.sp_Occupancy_GetByAssetId
    @AssetId INT,
    @TenantId INT,
    @AssociationId INT
AS
BEGIN
    SELECT o.*,
           (p.FirstName + ' ' + p.LastName) as PersonName,
           p.Email as Email,
           p.Phone as Phone,
           a.Name as AssetName
    FROM assoc.Occupancy o
    INNER JOIN assoc.Persons p ON o.PersonId = p.PersonId
    LEFT JOIN assoc.Assets a ON o.AssetId = a.AssetId
    WHERE o.AssetId = @AssetId AND o.AssociationId = @AssociationId;
END
GO

PRINT 'Updating assoc.sp_Occupancy_GetByUserId...'
GO
ALTER PROCEDURE assoc.sp_Occupancy_GetByUserId
    @UserId INT,
    @TenantId INT,
    @AssociationId INT
AS
BEGIN
    SELECT o.*,
           (p.FirstName + ' ' + p.LastName) as PersonName,
           p.Email as Email,
           p.Phone as Phone,
           a.Name as AssetName
    FROM assoc.Occupancy o
    INNER JOIN assoc.Persons p ON o.PersonId = p.PersonId
    INNER JOIN assoc.Users u ON p.Email = u.Email
    LEFT JOIN assoc.Assets a ON o.AssetId = a.AssetId
    WHERE u.UserId = @UserId AND o.AssociationId = @AssociationId;
END
GO

PRINT 'Updating assoc.sp_Occupancy_GetById...'
GO
ALTER PROCEDURE assoc.sp_Occupancy_GetById
    @Id INT,
    @TenantId INT,
    @AssociationId INT
AS
BEGIN
    SELECT o.*,
           (p.FirstName + ' ' + p.LastName) as PersonName,
           p.Email as Email,
           p.Phone as Phone,
           a.Name as AssetName
    FROM assoc.Occupancy o
    INNER JOIN assoc.Persons p ON o.PersonId = p.PersonId
    LEFT JOIN assoc.Assets a ON o.AssetId = a.AssetId
    WHERE o.OccupancyId = @Id AND o.AssociationId = @AssociationId;
END
GO
