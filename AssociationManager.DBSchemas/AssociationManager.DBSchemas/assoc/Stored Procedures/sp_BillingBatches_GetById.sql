CREATE   PROCEDURE assoc.sp_BillingBatches_GetById 
    @Id INT, 
    @TenantId INT, 
    @AssociationId INT 
AS 
BEGIN 
    SELECT b.*,
           CAST(CASE WHEN EXISTS (
               SELECT 1 FROM assoc.Invoices i 
               WHERE i.BillingBatchId = b.BillingBatchId 
                 AND i.Status = 'Draft'
           ) THEN 1 ELSE 0 END AS BIT) AS HasDraftInvoices
    FROM assoc.BillingBatches b 
    WHERE BillingBatchId = @Id AND TenantId = @TenantId AND AssociationId = @AssociationId; 
END