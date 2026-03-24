CREATE   PROCEDURE assoc.sp_Users_GetByAssociationId @AssociationId INT AS 
BEGIN 
    -- 1. Explicitly mapped users
    SELECT u.*, ua.Role 
    FROM assoc.Users u 
    JOIN assoc.UserAssociations ua ON u.UserId = ua.UserId 
    WHERE ua.AssociationId = @AssociationId
    
    UNION

    -- 2. Persons mapped as occupants (Residents)
    SELECT DISTINCT u.*, 'Resident' as Role
    FROM assoc.Users u
    INNER JOIN assoc.Persons p ON u.Email = p.Email
    INNER JOIN assoc.Occupancy o ON p.PersonId = o.PersonId
    WHERE o.AssociationId = @AssociationId;
END