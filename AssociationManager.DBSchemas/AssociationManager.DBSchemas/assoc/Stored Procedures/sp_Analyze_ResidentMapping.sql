-- 3. Analyze Resident Mapping
CREATE   PROCEDURE assoc.sp_Analyze_ResidentMapping
    @AssociationId INT = NULL
AS
BEGIN
    SELECT 
        a.Name AS AssetName,
        a.AssetType,
        p.FirstName + ' ' + p.LastName AS ResidentName,
        p.Email,
        p.Phone,
        o.OccupancyType,
        o.IsPrimaryContact,
        o.StartDate,
        o.EndDate
    FROM assoc.Assets a
    LEFT JOIN assoc.Occupancy o ON a.AssetId = o.AssetId
    LEFT JOIN assoc.Persons p ON o.PersonId = p.PersonId
    WHERE (@AssociationId IS NULL OR a.AssociationId = @AssociationId)
    ORDER BY a.Name, o.IsPrimaryContact DESC;
END