-- 4. Analyze Batch History
CREATE   PROCEDURE assoc.sp_Analyze_BatchHistory
    @AssociationId INT = NULL
AS
BEGIN
    SELECT 
        bb.BillingBatchId,
        bb.Month,
        bb.Year,
        bb.Status,
        bb.InvoicesGenerated,
        bb.TotalAmount,
        bb.CreatedDate,
        a.Name AS AssociationName
    FROM assoc.BillingBatches bb
    JOIN corp.Associations a ON bb.AssociationId = a.AssociationId
    WHERE (@AssociationId IS NULL OR bb.AssociationId = @AssociationId)
    ORDER BY bb.CreatedDate DESC;
END