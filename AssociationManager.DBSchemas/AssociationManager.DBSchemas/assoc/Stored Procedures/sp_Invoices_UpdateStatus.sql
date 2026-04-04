-- Update sp_Invoices_UpdateStatus to handle IsAdvancePaid
CREATE   PROCEDURE assoc.sp_Invoices_UpdateStatus
    @Id INT,
    @Status NVARCHAR(50),
    @TenantId INT,
    @AssociationId INT,
    @IsAdvancePaid BIT = NULL
AS
BEGIN
    UPDATE assoc.Invoices 
    SET Status = @Status,
        IsAdvancePaid = ISNULL(@IsAdvancePaid, IsAdvancePaid)
    WHERE InvoiceId = @Id 
      AND TenantId = @TenantId 
      AND (@AssociationId IS NULL OR AssociationId = @AssociationId);
END