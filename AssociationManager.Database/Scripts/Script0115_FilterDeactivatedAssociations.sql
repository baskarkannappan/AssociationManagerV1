-- Script0115_FilterDeactivatedAssociations.sql
-- Filter out deactivated associations from the tenant switcher and user context lists.

PRINT 'Updating corp.sp_Associations_GetByUserId...'
GO
CREATE OR ALTER PROCEDURE corp.sp_Associations_GetByUserId @UserId INT AS 
BEGIN
    SELECT DISTINCT a.* FROM corp.Associations a
    INNER JOIN corp.UserAssociations ua ON a.TenantId = ua.TenantId
    WHERE ua.UserId = @UserId AND ua.Role IN ('SystemAdmin', 'AssociationAdmin', 'PlatformAdmin') AND a.Status = 'Active'
    UNION
    SELECT DISTINCT a.* FROM corp.Associations a
    INNER JOIN assoc.Occupancy o ON a.AssociationId = o.AssociationId
    INNER JOIN assoc.Persons p ON o.PersonId = p.PersonId
    INNER JOIN corp.Users u ON p.Email = u.Email
    WHERE u.UserId = @UserId AND a.Status = 'Active'
END
GO

PRINT 'Updating assoc.sp_Associations_GetByUserId...'
GO
CREATE OR ALTER PROCEDURE assoc.sp_Associations_GetByUserId
    @UserId INT
AS
BEGIN
    IF EXISTS (SELECT 1 FROM assoc.Users WHERE UserId = @UserId AND Role IN ('SystemAdmin', 'PlatformAdmin', 'AssociationAdmin'))
    BEGIN
        SELECT * FROM corp.Associations WHERE [Status] = 'Active';
    END
    ELSE
    BEGIN
        -- 1. Direct mappings
        SELECT DISTINCT a.* FROM corp.Associations a
        INNER JOIN assoc.UserAssociations ua ON a.AssociationId = ua.AssociationId
        WHERE ua.UserId = @UserId AND a.[Status] = 'Active'
        
        UNION

        -- 2. Indirect mapping via Occupancy
        SELECT DISTINCT a.* FROM corp.Associations a
        INNER JOIN assoc.Occupancy o ON a.AssociationId = o.AssociationId
        INNER JOIN assoc.Persons p ON o.PersonId = p.PersonId
        INNER JOIN assoc.Users u ON p.Email = u.Email
        WHERE u.UserId = @UserId AND a.[Status] = 'Active'
    END
END;
GO
