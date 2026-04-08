-- RECONCILIATION SCRIPT
-- Objective: Sync "Completed" payments that are missing ledger entries.
-- This handles the ₹1,100 balance for the current user.

INSERT INTO assoc.Transactions (TenantId, AssociationId, AssetId, PaymentId, Amount, Type, Category, TransactionDate, Description)
SELECT 
    p.TenantId, 
    p.AssociationId, 
    p.AssetId, 
    p.PaymentId, 
    p.Amount, 
    'Credit' as Type, 
    'Advance Payment' as Category, 
    p.CreatedDate, 
    ISNULL(p.Notes, 'Payment Reconciliation')
FROM assoc.Payments p
LEFT JOIN assoc.Transactions t ON p.PaymentId = t.PaymentId
WHERE p.Status IN ('Paid', 'Completed')
  AND p.InvoiceId IS NULL  -- Advances only
  AND t.TransactionId IS NULL; -- Only those missing ledger entries

PRINT 'Reconciliation complete. Ledger synced with Payment History.';
