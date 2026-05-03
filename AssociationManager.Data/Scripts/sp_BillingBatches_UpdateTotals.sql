CREATE OR ALTER PROCEDURE assoc.sp_BillingBatches_UpdateTotals
    @Id INT,
    @TotalAmount DECIMAL(18,2),
    @InvoicesGenerated INT,
    @TenantId INT,
    @AssociationId INT
AS
BEGIN
    SET NOCOUNT ON;

    UPDATE assoc.BillingBatches
    SET TotalAmount = @TotalAmount,
        InvoicesGenerated = @InvoicesGenerated
    WHERE BillingBatchId = @Id
      AND TenantId = @TenantId
      AND AssociationId = @AssociationId;
END
