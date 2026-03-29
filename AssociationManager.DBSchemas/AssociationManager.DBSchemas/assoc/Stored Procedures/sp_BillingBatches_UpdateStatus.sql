CREATE   PROCEDURE assoc.sp_BillingBatches_UpdateStatus
    @Id INT,
    @Status NVARCHAR(50),
    @TenantId INT,
    @AssociationId INT
AS
BEGIN
    UPDATE assoc.BillingBatches 
    SET Status = @Status 
    WHERE BillingBatchId = @Id 
    AND TenantId = @TenantId 
    AND AssociationId = @AssociationId;
END;