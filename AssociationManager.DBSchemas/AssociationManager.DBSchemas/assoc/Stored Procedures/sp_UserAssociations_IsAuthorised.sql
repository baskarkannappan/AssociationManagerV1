CREATE   PROCEDURE assoc.sp_UserAssociations_IsAuthorised @UserId INT, @AssociationId INT AS 
BEGIN 
    IF EXISTS (SELECT 1 FROM assoc.Users WHERE UserId = @UserId AND Role IN ('SystemAdmin', 'PlatformAdmin'))
    BEGIN
        SELECT 1;
    END
    ELSE
    BEGIN
        SELECT COUNT(1) FROM assoc.UserAssociations 
        WHERE UserId = @UserId AND AssociationId = @AssociationId; 
    END
END;