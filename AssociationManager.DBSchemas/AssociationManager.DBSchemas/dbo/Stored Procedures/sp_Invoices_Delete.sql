-- Update sp_Invoices_Delete
CREATE   PROCEDURE sp_Invoices_Delete
    @Id INT,
    @TenantId INT,
    @AssociationId INT = NULL
AS
BEGIN
    DELETE FROM Invoices 
    WHERE InvoiceId = @Id AND TenantId = @TenantId 
    AND (AssociationId = @AssociationId OR @AssociationId IS NULL OR @AssociationId = 0);
END