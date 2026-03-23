-- Update sp_Invoices_GetById
CREATE   PROCEDURE sp_Invoices_GetById
    @Id INT,
    @TenantId INT,
    @AssociationId INT = NULL
AS
BEGIN
    SELECT i.*, a.Name as AssetName 
    FROM Invoices i 
    LEFT JOIN Assets a ON i.AssetId = a.AssetId
    WHERE i.InvoiceId = @Id AND i.TenantId = @TenantId
    AND (i.AssociationId = @AssociationId OR @AssociationId IS NULL OR @AssociationId = 0);
END