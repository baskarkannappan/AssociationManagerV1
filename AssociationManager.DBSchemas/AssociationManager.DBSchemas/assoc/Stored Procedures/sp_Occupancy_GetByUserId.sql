CREATE   PROCEDURE assoc.sp_Occupancy_GetByUserId
    @UserId INT,
    @TenantId INT,
    @AssociationId INT
AS
BEGIN
    SELECT o.*,
           (p.FirstName + ' ' + p.LastName) as PersonName,
           p.Email as Email
    FROM assoc.Occupancy o
    INNER JOIN assoc.Persons p ON o.PersonId = p.PersonId
    -- Join with assoc.Users because the API for Association context uses the assoc schema for User Repository
    INNER JOIN assoc.Users u ON p.Email = u.Email
    WHERE u.UserId = @UserId AND o.AssociationId = @AssociationId;
END
GO