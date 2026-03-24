CREATE   PROCEDURE corp.sp_Users_GetByTenantId @TenantId INT AS 
BEGIN 
    -- 1. Global corporate users
    SELECT u.*, ua.Role 
    FROM corp.Users u 
    JOIN corp.UserAssociations ua ON u.UserId = ua.UserId 
    WHERE ua.TenantId = @TenantId
    
    UNION

    -- 2. Residents from associations within the tenant
    SELECT DISTINCT u.*, 'Resident' as Role
    FROM corp.Users u
    INNER JOIN assoc.Persons p ON u.Email = p.Email
    INNER JOIN assoc.Occupancy o ON p.PersonId = o.PersonId
    INNER JOIN corp.Associations a ON o.AssociationId = a.AssociationId
    WHERE a.TenantId = @TenantId;
END