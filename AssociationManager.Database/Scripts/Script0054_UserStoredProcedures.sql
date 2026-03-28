-- User Management Stored Procedures

-- 1. Get All Users (Schema-aware)
CREATE OR ALTER PROCEDURE corp.sp_Users_List
AS
BEGIN
    SELECT * FROM corp.Users ORDER BY Name;
END;
GO

CREATE OR ALTER PROCEDURE assoc.sp_Users_List
AS
BEGIN
    SELECT * FROM assoc.Users ORDER BY Name;
END;
GO

-- 2. Delete User (Global)
CREATE OR ALTER PROCEDURE corp.sp_Users_DeleteGlobal
    @UserId INT
AS
BEGIN
    DELETE FROM corp.UserAssociations WHERE UserId = @UserId;
    DELETE FROM corp.Users WHERE UserId = @UserId;
END;
GO

CREATE OR ALTER PROCEDURE assoc.sp_Users_DeleteGlobal
    @UserId INT
AS
BEGIN
    DELETE FROM assoc.UserAssociations WHERE UserId = @UserId;
    DELETE FROM assoc.Users WHERE UserId = @UserId;
END;
GO

-- 3. Complex Authorisation Check (Tenant Level)
CREATE OR ALTER PROCEDURE corp.sp_Users_IsAuthorisedForAssociation
    @UserId INT,
    @AssociationId INT
AS
BEGIN
    SELECT COUNT(1) FROM (
        -- 1. High-level Admins see everything in their tenant
        SELECT a.AssociationId 
        FROM corp.Associations a
        INNER JOIN corp.UserAssociations ua ON a.TenantId = ua.TenantId
        WHERE ua.UserId = @UserId AND ua.Role IN ('SystemAdmin', 'AssociationAdmin') AND a.AssociationId = @AssociationId

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
GO

-- 4. Get Users by Association (Complex logic)
CREATE OR ALTER PROCEDURE corp.sp_Users_GetByAssociationId_Complex
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
GO

CREATE OR ALTER PROCEDURE corp.sp_Associations_List
AS
BEGIN
    SELECT * FROM corp.Associations;
END;
GO

-- 5. Asset Count (Move to SP)
CREATE OR ALTER PROCEDURE assoc.sp_Assets_Count
    @TenantId INT,
    @AssociationId INT
AS
BEGIN
    SELECT COUNT(*) FROM assoc.Assets 
    WHERE TenantId = @TenantId 
    AND AssociationId = @AssociationId 
    AND IsActive = 1;
END;
GO
