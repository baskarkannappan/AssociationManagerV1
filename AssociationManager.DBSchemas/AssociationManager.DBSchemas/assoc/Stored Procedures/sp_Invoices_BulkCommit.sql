CREATE   PROCEDURE assoc.sp_Invoices_BulkCommit
    @BatchId INT,
    @TenantId INT,
    @AssociationId INT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;
    SET DEADLOCK_PRIORITY NORMAL;

    -- Safety: Set Session Context for RLS isolation in case the connection factory hasn't set it yet.
    EXEC sp_set_session_context @key = N'TenantId', @value = @TenantId;
    EXEC sp_set_session_context @key = N'AssociationId', @value = @AssociationId;

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
    ;WITH BatchLineItemSums AS (
        SELECT li.InvoiceId, SUM(li.Amount) as TotalAmount
        FROM assoc.InvoiceLineItems li WITH (NOLOCK)
        JOIN assoc.Invoices i WITH (NOLOCK) ON li.InvoiceId = i.InvoiceId
        WHERE i.BillingBatchId = @BatchId 
          AND i.TenantId = @TenantId 
          AND i.AssociationId = @AssociationId
        GROUP BY li.InvoiceId
    )
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
    LEFT JOIN BatchLineItemSums li ON i.InvoiceId = li.InvoiceId
    WHERE i.BillingBatchId = @BatchId 
      AND i.TenantId = @TenantId 
      AND i.AssociationId = @AssociationId
      AND i.Status = 'Unpaid'
      AND NOT EXISTS (
          SELECT 1 FROM assoc.Transactions t WITH (NOLOCK) 
          WHERE t.InvoiceId = i.InvoiceId AND t.Type = 'Debit'
      );

    COMMIT TRANSACTION;

    -- 4. Sync Association Balances (Snapshot)
    EXEC assoc.sp_AssociationBalances_Sync @TenantId = @TenantId, @AssociationId = @AssociationId;
END