-- Update sp_Invoices_UpdateStatus
CREATE   PROCEDURE sp_Invoices_UpdateStatus
    @Id INT,
    @Status NVARCHAR(50),
    @TenantId INT,
    @AssociationId INT = NULL
AS
BEGIN
    UPDATE Invoices SET Status = @Status 
    WHERE InvoiceId = @Id AND TenantId = @TenantId 
    AND (AssociationId = @AssociationId OR @AssociationId IS NULL OR @AssociationId = 0);
END