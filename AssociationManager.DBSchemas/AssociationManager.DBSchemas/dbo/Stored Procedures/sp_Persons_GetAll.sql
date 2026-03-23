-- Update sp_Persons_GetAll to support Corporate Level (All associations in tenant)
CREATE   PROCEDURE sp_Persons_GetAll
    @TenantId INT,
    @AssociationId INT = NULL
AS
BEGIN
    SELECT * FROM Persons
    WHERE TenantId = @TenantId 
      AND (AssociationId = @AssociationId OR @AssociationId IS NULL OR @AssociationId = 0)
    ORDER BY LastName, FirstName;
END