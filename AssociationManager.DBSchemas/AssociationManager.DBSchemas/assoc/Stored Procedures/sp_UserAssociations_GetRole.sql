CREATE   PROCEDURE assoc.sp_UserAssociations_GetRole @UserId INT, @AssociationId INT AS 
BEGIN 
    IF EXISTS (SELECT 1 FROM assoc.UserAssociations WHERE UserId = @UserId AND AssociationId = @AssociationId)
        SELECT Role FROM assoc.UserAssociations WHERE UserId = @UserId AND AssociationId = @AssociationId;
    ELSE IF EXISTS (
        SELECT 1 FROM assoc.Occupancy o 
        INNER JOIN assoc.Persons p ON o.PersonId = p.PersonId
        INNER JOIN assoc.Users u ON p.Email = u.Email
        WHERE u.UserId = @UserId AND o.AssociationId = @AssociationId
    )
        SELECT 'Resident' as Role;
END