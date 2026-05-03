CREATE   PROCEDURE assoc.sp_BillingBatches_Update
    @BillingBatchId INT,
    @TenantId INT,
    @AssociationId INT,
    @Status NVARCHAR(50),
    @TotalAmount DECIMAL(18,2),
    @InvoicesGenerated INT
AS
BEGIN
    UPDATE assoc.BillingBatches
    SET 
        Status = @Status,
        TotalAmount = @TotalAmount,
        InvoicesGenerated = @InvoicesGenerated
    WHERE BillingBatchId = @BillingBatchId
    AND TenantId = @TenantId
    AND AssociationId = @AssociationId;
END