CREATE   PROCEDURE assoc.sp_BillingBatches_Create 
    @TenantId INT, 
    @AssociationId INT, 
    @Month INT, 
    @Year INT, 
    @Status NVARCHAR(50), 
    @TotalAmount DECIMAL(18,2), 
    @InvoicesGenerated INT, 
    @CreatedDate DATETIME 
AS 
BEGIN 
    INSERT INTO assoc.BillingBatches (TenantId, AssociationId, Month, Year, Status, TotalAmount, InvoicesGenerated, CreatedDate) 
    OUTPUT INSERTED.BillingBatchId 
    VALUES (@TenantId, @AssociationId, @Month, @Year, @Status, @TotalAmount, @InvoicesGenerated, @CreatedDate); 
END