CREATE   PROCEDURE assoc.sp_Invoices_BulkCommit
    @BatchId INT,
    @TenantId INT,
    @AssociationId INT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;
    SET DEADLOCK_PRIORITY NORMAL;

    BEGIN TRANSACTION;

    -- 1. Update Batch Status first
    UPDATE assoc.BillingBatches WITH (ROWLOCK)
    SET Status = 'Committed' 
    WHERE BillingBatchId = @BatchId AND TenantId = @TenantId AND AssociationId = @AssociationId;

    -- 2. Update all Draft Invoices to Unpaid for this batch
    UPDATE assoc.Invoices WITH (ROWLOCK)
    SET Status = 'Unpaid'
    WHERE BillingBatchId = @BatchId 
      AND TenantId = @TenantId 
      AND AssociationId = @AssociationId
      AND Status = 'Draft';

    -- 3. Bulk Insert Ledger Transactions (Debit)
    -- Unified Logic: We use the MAX of the recorded Amount or the sum of line items to prevent double-counting 
    -- while ensuring that line-item fines (which might be excluded from 'Amount' in some versions) are captured.
    INSERT INTO assoc.Transactions (
        TenantId, AssociationId, AssetId, InvoiceId, Type, Amount, Category, Description, TransactionDate
    )
    SELECT 
        i.TenantId, i.AssociationId, i.AssetId, i.InvoiceId, 'Debit', 
        CASE 
            WHEN ISNULL(li.TotalAmount, 0) > i.Amount THEN li.TotalAmount 
            ELSE i.Amount 
        END,
        'Billing', 
        'Batch Billing Committed: ' + i.Title, GETUTCDATE()
    FROM assoc.Invoices i WITH (NOLOCK)
    OUTER APPLY (
        SELECT SUM(Amount) as TotalAmount 
        FROM assoc.InvoiceLineItems WITH (NOLOCK)
        WHERE InvoiceId = i.InvoiceId
    ) li
    LEFT JOIN assoc.Transactions t WITH (NOLOCK) ON i.InvoiceId = t.InvoiceId AND t.Type = 'Debit'
    WHERE i.BillingBatchId = @BatchId 
      AND i.TenantId = @TenantId 
      AND i.AssociationId = @AssociationId
      AND i.Status = 'Unpaid'
      AND t.TransactionId IS NULL;

    COMMIT TRANSACTION;

    -- 4. Sync Association Balances (Snapshot)
    EXEC assoc.sp_AssociationBalances_Sync @TenantId = @TenantId, @AssociationId = @AssociationId;
END