-- Update sp_Persons_GetById
CREATE   PROCEDURE sp_Persons_GetById
    @Id INT,
    @TenantId INT,
    @AssociationId INT = NULL
AS
BEGIN
    SELECT * FROM Persons
    WHERE PersonId = @Id AND TenantId = @TenantId
    AND (AssociationId = @AssociationId OR @AssociationId IS NULL OR @AssociationId = 0);
END