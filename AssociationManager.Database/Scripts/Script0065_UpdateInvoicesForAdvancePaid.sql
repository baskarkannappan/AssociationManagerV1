-- Migration Script: Add IsAdvancePaid to Invoices
IF NOT EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID('assoc.Invoices') AND name = 'IsAdvancePaid')
BEGIN
    ALTER TABLE assoc.Invoices ADD IsAdvancePaid BIT NOT NULL DEFAULT 0;
END
GO

-- Update sp_Invoices_UpdateStatus to handle IsAdvancePaid
CREATE OR ALTER PROCEDURE assoc.sp_Invoices_UpdateStatus
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
GO
