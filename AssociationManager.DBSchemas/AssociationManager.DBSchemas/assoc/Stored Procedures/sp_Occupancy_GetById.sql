CREATE   PROCEDURE assoc.sp_Occupancy_GetById 
    @Id INT, 
    @TenantId INT, 
    @AssociationId INT 
AS 
BEGIN 
    SELECT o.*, 
           (p.FirstName + ' ' + p.LastName) as PersonName, 
           p.Email as Email 
    FROM assoc.Occupancy o
    JOIN assoc.Persons p ON o.PersonId = p.PersonId
    WHERE o.OccupancyId = @Id AND o.AssociationId = @AssociationId; 
END