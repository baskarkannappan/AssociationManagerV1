CREATE PROCEDURE assoc.sp_Invoices_GetByBatchId
    @BatchId INT,
    @TenantId INT
AS
BEGIN
    SET NOCOUNT ON;
    SELECT * FROM assoc.Invoices 
    WHERE BillingBatchId = @BatchId 
    AND TenantId = @TenantId;
END;