CREATE   PROCEDURE assoc.sp_UserAssociations_IsAuthorised @UserId INT, @AssociationId INT AS 
BEGIN 
    IF EXISTS (SELECT 1 FROM assoc.Users WHERE UserId = @UserId AND Role IN ('SystemAdmin', 'PlatformAdmin'))
    BEGIN
        SELECT 1;
    END
    ELSE
    BEGIN
        SELECT COUNT(1) FROM (
            -- Direct mapping
            SELECT AssociationId FROM assoc.UserAssociations WHERE UserId = @UserId AND AssociationId = @AssociationId
            UNION
            -- Implicit mapping via occupancy
            SELECT o.AssociationId FROM assoc.Occupancy o 
            INNER JOIN assoc.Persons p ON o.PersonId = p.PersonId
            INNER JOIN assoc.Users u ON p.Email = u.Email
            WHERE u.UserId = @UserId AND o.AssociationId = @AssociationId
        ) AS AuthCheck;
    END
END