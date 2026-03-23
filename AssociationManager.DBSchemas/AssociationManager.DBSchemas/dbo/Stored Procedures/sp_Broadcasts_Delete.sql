-- Update sp_Broadcasts_Delete
CREATE   PROCEDURE sp_Broadcasts_Delete
    @Id INT,
    @TenantId INT,
    @AssociationId INT = NULL
AS
BEGIN
    DELETE FROM Broadcasts 
    WHERE BroadcastId = @Id AND TenantId = @TenantId
    AND (AssociationId = @AssociationId OR @AssociationId IS NULL OR @AssociationId = 0);
END