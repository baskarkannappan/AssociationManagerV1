-- Script 0025: Inclusive Association Visibility for Managers
GO
CREATE OR ALTER PROCEDURE sp_Associations_GetByUserId
    @UserId INT
AS
BEGIN
    SET NOCOUNT ON;

    -- 1. All Admin and Manager roles see all associations in their tenant
    SELECT DISTINCT a.* 
    FROM Associations a
    INNER JOIN UserAssociations ua ON a.TenantId = ua.TenantId
    WHERE ua.UserId = @UserId 
      AND ua.Role IN ('SystemAdmin', 'AssociationAdmin', 'UserManager', 'AssetManager', 'FinanceManager')

    UNION

    -- 2. Residents and others only see associations they are directly linked to via Occupancy
    SELECT DISTINCT a.*
    FROM Associations a
    INNER JOIN Occupancy o ON a.AssociationId = o.AssociationId
    INNER JOIN Persons p ON o.PersonId = p.PersonId
    INNER JOIN Users u ON p.Email = u.Email
    WHERE u.UserId = @UserId
END
GO
