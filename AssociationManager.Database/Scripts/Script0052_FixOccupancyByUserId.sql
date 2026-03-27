-- Script0052_FixOccupancyByUserId.sql
-- Fix the stored procedure to join with the appropriate Users table (assoc.Users)

PRINT 'Updating assoc.sp_Occupancy_GetByUserId to use assoc.Users...'
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
    -- Join with assoc.Users because the API for Association context uses the assoc schema for User Repository
    INNER JOIN assoc.Users u ON p.Email = u.Email
    WHERE u.UserId = @UserId AND o.AssociationId = @AssociationId;
END
GO

PRINT 'Updating assoc.sp_Associations_GetByUserId to ensure consistency...'
GO

CREATE OR ALTER PROCEDURE assoc.sp_Associations_GetByUserId 
    @UserId INT 
AS
BEGIN
    -- 1. High-level Admins mapped in assoc.Users
    IF EXISTS (SELECT 1 FROM assoc.Users WHERE UserId = @UserId AND Role IN ('SystemAdmin', 'PlatformAdmin', 'AssociationAdmin'))
    BEGIN
        SELECT DISTINCT a.* 
        FROM corp.Associations a
        INNER JOIN assoc.Users u ON a.TenantId = u.TenantId -- For assoc, TenantId in Users table usually means AssociationId or Tenant context
        WHERE u.UserId = @UserId;
    END

    -- 2. Indirect mappings via Occupancy (using email bridge to assoc.Users)
    SELECT DISTINCT a.* 
    FROM corp.Associations a
    INNER JOIN assoc.Occupancy o ON a.AssociationId = o.AssociationId
    INNER JOIN assoc.Persons p ON o.PersonId = p.PersonId
    INNER JOIN assoc.Users u ON p.Email = u.Email
    WHERE u.UserId = @UserId;
END
GO

PRINT 'Script 0052 Complete.'
GO
