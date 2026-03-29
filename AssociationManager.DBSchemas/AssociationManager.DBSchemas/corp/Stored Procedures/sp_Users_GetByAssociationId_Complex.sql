
-- 4. Get Users by Association (Complex logic)
CREATE   PROCEDURE corp.sp_Users_GetByAssociationId_Complex
    @AssociationId INT
AS
BEGIN
    SELECT DISTINCT u.*
    FROM corp.Users u
    LEFT JOIN assoc.Persons p ON u.Email = p.Email
    LEFT JOIN assoc.Occupancy o ON p.PersonId = o.PersonId
    LEFT JOIN corp.UserAssociations ua ON u.TenantId = ua.TenantId
    WHERE 
        u.AssociationId = @AssociationId -- Active association
        OR o.AssociationId = @AssociationId -- Resident association
        OR (ua.Role IN ('SystemAdmin', 'AssociationAdmin') AND u.TenantId = (SELECT TenantId FROM corp.Associations WHERE AssociationId = @AssociationId))
    ORDER BY u.Name;
END;