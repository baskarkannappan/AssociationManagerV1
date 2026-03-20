-- Script 0023: Refine Association Filtering for SWITCHER
GO
CREATE OR ALTER PROCEDURE sp_Associations_GetByUserId
    @UserId INT
AS
BEGIN
    SET NOCOUNT ON;

    -- 1. High-level Admins see everything in their tenant
    SELECT DISTINCT a.* 
    FROM Associations a
    INNER JOIN UserAssociations ua ON a.TenantId = ua.TenantId
    WHERE ua.UserId = @UserId 
      AND ua.Role IN ('SystemAdmin', 'AssociationAdmin')

    UNION

    -- 2. Everyone else (Resident, UserManager, AssetManager, etc.) 
    -- only see associations they are directly linked to via Occupancy/Assets
    SELECT DISTINCT a.*
    FROM Associations a
    INNER JOIN Occupancy o ON a.AssociationId = o.AssociationId
    INNER JOIN Persons p ON o.PersonId = p.PersonId
    INNER JOIN Users u ON p.Email = u.Email
    WHERE u.UserId = @UserId
END
GO
