
CREATE   PROCEDURE assoc.sp_UserAssociations_GetRole
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