CREATE   PROCEDURE assoc.sp_Occupancy_GetByUserId
    @UserId INT,
    @TenantId INT,
    @AssociationId INT
AS
BEGIN
    SELECT o.*,
           (p.FirstName + ' ' + p.LastName) as PersonName,
           p.Email as Email,
           a.Name as AssetName
    FROM assoc.Occupancy o
    INNER JOIN assoc.Persons p ON o.PersonId = p.PersonId
    INNER JOIN assoc.Users u ON p.Email = u.Email
    LEFT JOIN assoc.Assets a ON o.AssetId = a.AssetId
    WHERE u.UserId = @UserId AND o.AssociationId = @AssociationId;
END