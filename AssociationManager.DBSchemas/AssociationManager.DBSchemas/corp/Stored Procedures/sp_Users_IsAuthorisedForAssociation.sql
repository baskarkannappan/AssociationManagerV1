
-- 3. Complex Authorisation Check (Tenant Level)
CREATE   PROCEDURE corp.sp_Users_IsAuthorisedForAssociation
    @UserId INT,
    @AssociationId INT
AS
BEGIN
    SELECT COUNT(1) FROM (
        -- 1. High-level Admins see everything in their tenant
        SELECT a.AssociationId 
        FROM corp.Associations a
        INNER JOIN corp.UserAssociations ua ON a.TenantId = ua.TenantId
        WHERE ua.UserId = @UserId AND ua.Role IN ('SystemAdmin', 'PlatformAdmin', 'AssociationAdmin') AND a.AssociationId = @AssociationId

        UNION

        -- 2. Residents & Staff linked to assets/occupancy
        SELECT a.AssociationId
        FROM corp.Associations a
        INNER JOIN assoc.Occupancy o ON a.AssociationId = o.AssociationId
        INNER JOIN assoc.Persons p ON o.PersonId = p.PersonId
        INNER JOIN corp.Users u ON p.Email = u.Email
        WHERE u.UserId = @UserId AND a.AssociationId = @AssociationId
    ) AS AuthCheck;
END;