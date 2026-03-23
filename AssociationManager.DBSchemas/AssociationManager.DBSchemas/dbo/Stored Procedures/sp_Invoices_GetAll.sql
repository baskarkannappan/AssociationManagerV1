-- Update sp_Invoices_GetAll to support Corporate Level (All associations in tenant)
CREATE   PROCEDURE sp_Invoices_GetAll
    @TenantId INT,
    @AssociationId INT = NULL
AS
BEGIN
    SELECT i.*, a.Name as AssetName 
    FROM Invoices i 
    LEFT JOIN Assets a ON i.AssetId = a.AssetId
    WHERE i.TenantId = @TenantId 
      AND (i.AssociationId = @AssociationId OR @AssociationId IS NULL OR @AssociationId = 0)
    ORDER BY i.DueDate DESC;
END