-- 9. Update sp_Associations_GetByUserId to include status
CREATE   PROCEDURE corp.sp_Associations_GetByUserId @UserId INT AS 
BEGIN
    SELECT DISTINCT a.* FROM corp.Associations a
    INNER JOIN corp.UserAssociations ua ON a.TenantId = ua.TenantId
    WHERE ua.UserId = @UserId AND ua.Role IN ('SystemAdmin', 'AssociationAdmin', 'PlatformAdmin')
    UNION
    SELECT DISTINCT a.* FROM corp.Associations a
    INNER JOIN assoc.Occupancy o ON a.AssociationId = o.AssociationId
    INNER JOIN assoc.Persons p ON o.PersonId = p.PersonId
    INNER JOIN corp.Users u ON p.Email = u.Email
    WHERE u.UserId = @UserId
END