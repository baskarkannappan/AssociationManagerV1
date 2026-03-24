
-- GET ASSOCIATIONS BY USER ID (ASSOC SCHEMA)
CREATE   PROCEDURE assoc.sp_Associations_GetByUserId @UserId INT AS 
BEGIN
    IF EXISTS (SELECT 1 FROM assoc.Users WHERE UserId = @UserId AND Role IN ('SystemAdmin', 'PlatformAdmin'))
    BEGIN
        SELECT * FROM corp.Associations;
    END
    ELSE
    BEGIN
        -- 1. Direct mappings in assoc.UserAssociations
        SELECT DISTINCT a.* FROM corp.Associations a
        INNER JOIN assoc.UserAssociations ua ON a.AssociationId = ua.AssociationId
        WHERE ua.UserId = @UserId
        
        UNION

        -- 2. Indirect mappings via Occupancy (using email bridge)
        SELECT DISTINCT a.* FROM corp.Associations a
        INNER JOIN assoc.Occupancy o ON a.AssociationId = o.AssociationId
        INNER JOIN assoc.Persons p ON o.PersonId = p.PersonId
        INNER JOIN assoc.Users u ON p.Email = u.Email
        WHERE u.UserId = @UserId
    END
END