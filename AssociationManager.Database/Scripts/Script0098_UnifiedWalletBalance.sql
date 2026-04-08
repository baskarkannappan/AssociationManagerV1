-- Script0098_UnifiedWalletBalance.sql
-- Provides a fail-safe, database-level calculation for personal wallet balances.
-- This ensures that the balance card and history grid are natively synchronized.

CREATE OR ALTER PROCEDURE assoc.sp_Finance_GetPersonalWalletBalance
    @TenantId INT,
    @AssociationId INT,
    @UserId INT
AS
BEGIN
    SET NOCOUNT ON;

    -- 1. Resolve all relevant assets for this user in this association
    DECLARE @Assets TABLE (AssetId INT);

    -- Branch A: Official Occupancy (User -> Email -> Person -> Occupancy)
    INSERT INTO @Assets (AssetId)
    SELECT DISTINCT o.AssetId 
    FROM assoc.Occupancy o
    INNER JOIN assoc.Persons p ON o.PersonId = p.PersonId
    INNER JOIN assoc.Users u ON p.Email = u.Email
    WHERE u.UserId = @UserId 
      AND o.TenantId = @TenantId 
      AND o.AssociationId = @AssociationId;

    -- Branch B: Payment History (Assets where the user has successfully made advance payments)
    INSERT INTO @Assets (AssetId)
    SELECT DISTINCT p.AssetId 
    FROM assoc.Payments p
    WHERE p.UserId = @UserId 
      AND p.TenantId = @TenantId 
      AND p.AssociationId = @AssociationId
      AND p.AssetId IS NOT NULL
      AND p.AssetId NOT IN (SELECT AssetId FROM @Assets);

    -- 2. Final Sum from the Transaction Ledger
    -- We sum all 'Credits' (Deposits) and subtract all 'Debits' (Settlements/Refunds)
    SELECT ISNULL(SUM(CASE 
        -- Credits: Advance Payments and Top-ups
        WHEN t.Type = 'Credit' 
             AND (t.Category IS NULL OR t.Category = 'Payment' OR t.Category = 'Advance Payment') 
             AND (t.InvoiceId IS NULL OR t.InvoiceId = 0) 
        THEN t.Amount
        
        -- Debits: Wallet deductions for invoice settlement
        WHEN t.Type = 'Debit' 
             AND t.Category = 'Credit Settlement' 
        THEN -t.Amount
        
        ELSE 0 
    END), 0)
    FROM assoc.Transactions t
    WHERE t.AssetId IN (SELECT AssetId FROM @Assets)
      AND t.TenantId = @TenantId
      AND t.AssociationId = @AssociationId;
END
GO
