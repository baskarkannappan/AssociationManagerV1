-- Update sp_Broadcasts_GetAll to support Corporate Level (All associations in tenant)
CREATE OR ALTER PROCEDURE sp_Broadcasts_GetAll
    @TenantId INT,
    @AssociationId INT = NULL
AS
BEGIN
    SELECT b.*, u.FirstName + ' ' + u.LastName as AuthorName, a.Name as AssetName
    FROM Broadcasts b
    JOIN Users u ON b.CreatedBy = u.UserId
    LEFT JOIN Assets a ON b.AssetId = a.AssetId
    WHERE b.TenantId = @TenantId 
      AND (b.AssociationId = @AssociationId OR @AssociationId IS NULL OR @AssociationId = 0)
    ORDER BY b.IsPinned DESC, b.CreatedDate DESC;
END
GO

-- Update sp_Broadcasts_GetById
CREATE OR ALTER PROCEDURE sp_Broadcasts_GetById
    @Id INT,
    @TenantId INT,
    @AssociationId INT = NULL
AS
BEGIN
    SELECT b.*, u.FirstName + ' ' + u.LastName as AuthorName, a.Name as AssetName
    FROM Broadcasts b
    JOIN Users u ON b.CreatedBy = u.UserId
    LEFT JOIN Assets a ON b.AssetId = a.AssetId
    WHERE b.BroadcastId = @Id AND b.TenantId = @TenantId
    AND (b.AssociationId = @AssociationId OR @AssociationId IS NULL OR @AssociationId = 0);
END
GO

-- Update sp_Broadcasts_Delete
CREATE OR ALTER PROCEDURE sp_Broadcasts_Delete
    @Id INT,
    @TenantId INT,
    @AssociationId INT = NULL
AS
BEGIN
    DELETE FROM Broadcasts 
    WHERE BroadcastId = @Id AND TenantId = @TenantId
    AND (AssociationId = @AssociationId OR @AssociationId IS NULL OR @AssociationId = 0);
END
GO
