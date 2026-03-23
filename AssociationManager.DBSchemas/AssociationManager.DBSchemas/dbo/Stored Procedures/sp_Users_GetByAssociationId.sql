CREATE   PROCEDURE [dbo].[sp_Users_GetByAssociationId]
    @AssociationId INT
AS
BEGIN
    SELECT DISTINCT u.*
    FROM Users u
    LEFT JOIN Persons p ON u.Email = p.Email
    LEFT JOIN Occupancy o ON p.PersonId = o.PersonId
    LEFT JOIN UserAssociations ua ON u.TenantId = ua.TenantId
    WHERE 
        u.AssociationId = @AssociationId -- Active association
        OR o.AssociationId = @AssociationId -- Resident association
        OR (ua.Role IN ('SystemAdmin', 'AssociationAdmin') AND u.TenantId = (SELECT TenantId FROM Associations WHERE AssociationId = @AssociationId))
    ORDER BY u.Name
END