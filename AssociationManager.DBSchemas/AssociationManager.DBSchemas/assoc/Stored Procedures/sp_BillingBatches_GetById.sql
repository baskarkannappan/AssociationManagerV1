CREATE   PROCEDURE assoc.sp_BillingBatches_GetById 
    @Id INT, 
    @TenantId INT, 
    @AssociationId INT 
AS 
BEGIN 
    SELECT * FROM assoc.BillingBatches WHERE BillingBatchId = @Id AND TenantId = @TenantId AND AssociationId = @AssociationId; 
END