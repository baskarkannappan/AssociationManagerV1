CREATE   PROCEDURE assoc.sp_Occupancy_GetByUserId @UserId INT, @TenantId INT, @AssociationId INT AS 
BEGIN
    SELECT o.* FROM assoc.Occupancy o
    INNER JOIN assoc.Persons p ON o.PersonId = p.PersonId
    INNER JOIN assoc.Users u ON p.Email = u.Email
    WHERE u.UserId = @UserId AND o.AssociationId = @AssociationId;
END
GO