-- Update sp_Broadcasts_GetById
CREATE   PROCEDURE sp_Broadcasts_GetById
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