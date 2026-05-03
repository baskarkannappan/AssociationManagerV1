-- 4. Stored Procedure for Idempotent Batch Check
CREATE   PROCEDURE [assoc].[sp_BillingBatches_GetDraft]
    @AssociationId INT,
    @Month INT,
    @Year INT,
    @TenantId INT
AS
BEGIN
    SELECT TOP 1 *
    FROM [assoc].[BillingBatches]
    WHERE AssociationId = @AssociationId 
      AND Month = @Month 
      AND Year = @Year 
      AND Status = 'Draft'
      AND TenantId = @TenantId
    ORDER BY BillingBatchId DESC;
END