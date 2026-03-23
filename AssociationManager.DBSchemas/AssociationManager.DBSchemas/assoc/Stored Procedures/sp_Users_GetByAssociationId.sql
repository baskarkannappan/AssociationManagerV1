CREATE   PROCEDURE assoc.sp_Users_GetByAssociationId @AssociationId INT AS 
BEGIN 
    SELECT u.*, ua.Role 
    FROM assoc.Users u 
    JOIN assoc.UserAssociations ua ON u.UserId = ua.UserId 
    WHERE ua.AssociationId = @AssociationId; 
END