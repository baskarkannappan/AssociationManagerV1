CREATE OR ALTER PROCEDURE assoc.sp_BillingBatches_Delete
    @BatchId INT,
    @TenantId INT,
    @AssociationId INT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    BEGIN TRANSACTION;

    BEGIN TRY
        -- Check if the batch is in 'Draft', 'COMMIT_FAILED' status
        -- OR if it's 'Committed' but still contains 'Draft' invoices (indicating data inconsistency)
        IF NOT EXISTS (
            SELECT 1 FROM assoc.BillingBatches b 
            WHERE b.BillingBatchId = @BatchId 
              AND (
                b.Status IN ('Draft', 'COMMIT_FAILED')
                OR (b.Status = 'Committed' AND EXISTS (SELECT 1 FROM assoc.Invoices i WHERE i.BillingBatchId = b.BillingBatchId AND i.Status = 'Draft'))
              )
        )
        BEGIN
            THROW 50000, 'Only Draft, Failed, or inconsistent batches can be deleted.', 1;
        END

        -- 1. Delete Line Items for these invoices
        DELETE li
        FROM assoc.InvoiceLineItems li
        INNER JOIN assoc.Invoices i ON li.InvoiceId = i.InvoiceId
        WHERE i.BillingBatchId = @BatchId AND i.TenantId = @TenantId AND i.AssociationId = @AssociationId;

        -- 2. Delete Invoices in the batch (only those still marked Draft)
        DELETE FROM assoc.Invoices 
        WHERE BillingBatchId = @BatchId AND TenantId = @TenantId AND AssociationId = @AssociationId AND Status = 'Draft';

        -- 3. Delete the Batch record
        DELETE FROM assoc.BillingBatches 
        WHERE BillingBatchId = @BatchId AND TenantId = @TenantId AND AssociationId = @AssociationId;

        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK;
        THROW;
    END CATCH
END
