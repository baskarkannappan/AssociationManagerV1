CREATE   PROCEDURE assoc.sp_Occupancy_GetByAssetId
    @AssetId INT,
    @TenantId INT,
    @AssociationId INT
AS
BEGIN
    SELECT o.*,
           (p.FirstName + ' ' + p.LastName) as PersonName,
           p.Email as Email,
           p.Phone as Phone,
           a.Name as AssetName
    FROM assoc.Occupancy o
    INNER JOIN assoc.Persons p ON o.PersonId = p.PersonId
    LEFT JOIN assoc.Assets a ON o.AssetId = a.AssetId
    WHERE o.AssetId = @AssetId AND o.AssociationId = @AssociationId;
END