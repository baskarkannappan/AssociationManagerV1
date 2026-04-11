CREATE PROCEDURE corp.sp_Users_GetByAssociationId_Complex
    @AssociationId INT
AS
BEGIN
    SET NOCOUNT ON;

    -- Branch 1: Directly assigned users
    SELECT u.*
    FROM corp.Users u
    WHERE u.AssociationId = @AssociationId

    UNION

    -- Branch 2: Residents via Occupancy
    -- Note: Uses JOIN instead of LEFT JOIN/OR to force index usage
    SELECT u.*
    FROM corp.Users u
    INNER JOIN assoc.Persons p ON u.Email = p.Email
    INNER JOIN assoc.Occupancy o ON p.PersonId = o.PersonId
    WHERE o.AssociationId = @AssociationId

    UNION

    -- Branch 3: Admins via Tenant association
    SELECT u.*
    FROM corp.Users u
    INNER JOIN corp.UserAssociations ua ON u.TenantId = ua.TenantId
    WHERE ua.Role IN ('SystemAdmin', 'AssociationAdmin') 
      AND u.TenantId = (SELECT TOP 1 TenantId FROM corp.Associations WHERE AssociationId = @AssociationId)

    ORDER BY Name;
END