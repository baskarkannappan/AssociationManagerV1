-- Update sp_Persons_GetAll to support Corporate Level (All associations in tenant)
CREATE OR ALTER PROCEDURE sp_Persons_GetAll
    @TenantId INT,
    @AssociationId INT = NULL
AS
BEGIN
    SELECT * FROM Persons
    WHERE TenantId = @TenantId 
      AND (AssociationId = @AssociationId OR @AssociationId IS NULL OR @AssociationId = 0)
    ORDER BY LastName, FirstName;
END
GO

-- Update sp_Persons_GetById
CREATE OR ALTER PROCEDURE sp_Persons_GetById
    @Id INT,
    @TenantId INT,
    @AssociationId INT = NULL
AS
BEGIN
    SELECT * FROM Persons
    WHERE PersonId = @Id AND TenantId = @TenantId
    AND (AssociationId = @AssociationId OR @AssociationId IS NULL OR @AssociationId = 0);
END
GO

-- Update sp_Persons_Delete
CREATE OR ALTER PROCEDURE sp_Persons_Delete
    @Id INT,
    @TenantId INT,
    @AssociationId INT = NULL
AS
BEGIN
    DELETE FROM Persons 
    WHERE PersonId = @Id AND TenantId = @TenantId
    AND (AssociationId = @AssociationId OR @AssociationId IS NULL OR @AssociationId = 0);
END
GO
