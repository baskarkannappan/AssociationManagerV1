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
GO

CREATE OR ALTER PROCEDURE assoc.sp_UserAssociations_IsAuthorised
    @UserId INT,
    @AssociationId INT
AS
BEGIN
    IF EXISTS (SELECT 1 FROM assoc.Users WHERE UserId = @UserId AND Role IN ('SystemAdmin', 'PlatformAdmin', 'AssociationAdmin'))
    BEGIN
        SELECT 1;
    END
    ELSE
    BEGIN
        SELECT COUNT(1) FROM (
            -- 1. Direct mapping
            SELECT AssociationId FROM assoc.UserAssociations WHERE UserId = @UserId AND AssociationId = @AssociationId
            UNION
            -- 2. Implicit mapping via occupancy (using Email bridge to be safe)
            SELECT o.AssociationId FROM assoc.Occupancy o 
            INNER JOIN assoc.Persons p ON o.PersonId = p.PersonId
            INNER JOIN assoc.Users u ON p.Email = u.Email
            WHERE u.UserId = @UserId AND o.AssociationId = @AssociationId
        ) AS AuthCheck;
    END
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

-- 6. Associations List for User (Schema-aware)
CREATE OR ALTER PROCEDURE assoc.sp_Associations_GetByUserId
    @UserId INT
AS
BEGIN
    IF EXISTS (SELECT 1 FROM assoc.Users WHERE UserId = @UserId AND Role IN ('SystemAdmin', 'PlatformAdmin', 'AssociationAdmin'))
    BEGIN
        SELECT * FROM corp.Associations;
    END
    ELSE
    BEGIN
        -- 1. Direct mappings
        SELECT DISTINCT a.* FROM corp.Associations a
        INNER JOIN assoc.UserAssociations ua ON a.AssociationId = ua.AssociationId
        WHERE ua.UserId = @UserId
        
        UNION

        -- 2. Indirect mapping via Occupancy
        SELECT DISTINCT a.* FROM corp.Associations a
        INNER JOIN assoc.Occupancy o ON a.AssociationId = o.AssociationId
        INNER JOIN assoc.Persons p ON o.PersonId = p.PersonId
        INNER JOIN assoc.Users u ON p.Email = u.Email
        WHERE u.UserId = @UserId
    END
END;
GO

-- 7. Get Role for Context (Schema-aware)
CREATE OR ALTER PROCEDURE corp.sp_UserAssociations_GetRole
    @UserId INT,
    @TenantId INT
AS
BEGIN
    -- 1. Check direct tenant mapping
    DECLARE @Role NVARCHAR(50) = (SELECT TOP 1 Role FROM corp.UserAssociations WHERE UserId = @UserId AND TenantId = @TenantId);
    
    IF @Role IS NOT NULL
        SELECT @Role;
    ELSE
    BEGIN
        -- 2. Check if user is global admin in corp.Users
        SELECT Role FROM corp.Users WHERE UserId = @UserId AND Role IN ('SystemAdmin', 'PlatformAdmin');
    END
END;
GO

CREATE OR ALTER PROCEDURE assoc.sp_UserAssociations_GetRole
    @UserId INT,
    @AssociationId INT
AS
BEGIN
    -- 1. Check direct association mapping
    DECLARE @Role NVARCHAR(50) = (SELECT TOP 1 Role FROM assoc.UserAssociations WHERE UserId = @UserId AND AssociationId = @AssociationId);
    
    IF @Role IS NOT NULL
        SELECT @Role;
    ELSE
    BEGIN
        -- 2. Check if user is high-level admin in assoc.Users
        SET @Role = (SELECT TOP 1 Role FROM assoc.Users WHERE UserId = @UserId AND Role IN ('SystemAdmin', 'PlatformAdmin', 'AssociationAdmin'));
        
        IF @Role IS NOT NULL
            SELECT @Role;
        ELSE
        BEGIN
            -- 3. Check occupancy for implicit Resident role
            IF EXISTS (SELECT 1 FROM assoc.Occupancy o 
                       INNER JOIN assoc.Persons p ON o.PersonId = p.PersonId 
                       INNER JOIN assoc.Users u ON p.Email = u.Email 
                       WHERE u.UserId = @UserId AND o.AssociationId = @AssociationId)
                SELECT 'Resident';
            ELSE
                SELECT NULL;
        END
    END
END;
GO
