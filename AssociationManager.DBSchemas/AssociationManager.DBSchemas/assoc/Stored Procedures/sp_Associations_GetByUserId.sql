CREATE OR ALTER PROCEDURE assoc.sp_Associations_GetByUserId
    @UserId INT
AS
BEGIN
    -- Only SystemAdmin should see everything. 
    -- PlatformAdmin and AssociationAdmin should be restricted to their mapped associations in this portal.
    IF EXISTS (SELECT 1 FROM assoc.Users WHERE UserId = @UserId AND Role = 'SystemAdmin')
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