-- Script0098_UnifiedWalletBalance.sql
-- Provides a fail-safe, database-level calculation for personal wallet balances.
-- This ensures that the balance card and history grid are natively synchronized.

CREATE   PROCEDURE assoc.sp_Finance_GetPersonalWalletBalance
    @TenantId INT,
    @AssociationId INT,
    @UserId INT
AS
BEGIN
    SET NOCOUNT ON;

    -- NEW: Role Check for Admin Consolidation
    DECLARE @IsAdmin BIT = 0;
    IF EXISTS (
        SELECT 1 FROM corp.UserAssociations WHERE UserId = @UserId AND TenantId = @TenantId AND Role = 'AssociationAdmin'
        UNION
        SELECT 1 FROM assoc.Users WHERE UserId = @UserId AND TenantId = @TenantId AND (Role = 'AssociationAdmin' OR Role = 'Admin')
    )
    BEGIN
        SET @IsAdmin = 1;
    END

    -- 1. Resolve all relevant assets
    DECLARE @Assets TABLE (AssetId INT);

    IF @IsAdmin = 1
    BEGIN
        -- Admin View: Consolidate ALL assets for the association
        INSERT INTO @Assets (AssetId)
        SELECT AssetId FROM assoc.Assets 
        WHERE TenantId = @TenantId 
          AND (@AssociationId IS NULL OR AssociationId = @AssociationId OR @AssociationId = 0);
    END
    ELSE
    BEGIN
        -- Resident View: Robust Identity Resolution (resolves from either schema)
        DECLARE @UserEmail NVARCHAR(255);
        SELECT @UserEmail = Email FROM corp.Users WHERE UserId = @UserId;
        
        IF @UserEmail IS NULL
            SELECT @UserEmail = Email FROM assoc.Users WHERE UserId = @UserId AND TenantId = @TenantId;

        -- Branch A: Official Occupancy (User -> Email -> Person -> Occupancy)
        INSERT INTO @Assets (AssetId)
        SELECT DISTINCT o.AssetId 
        FROM assoc.Occupancy o
        INNER JOIN assoc.Persons p ON o.PersonId = p.PersonId
        WHERE (p.Email = @UserEmail OR (p.Email IS NOT NULL AND p.Email = (SELECT Email FROM assoc.Users WHERE UserId = @UserId AND TenantId = @TenantId)))
          AND o.TenantId = @TenantId 
          AND o.AssociationId = @AssociationId;

        -- Branch B: Payment History (Match by Email OR UserId to handle all identity states)
        INSERT INTO @Assets (AssetId)
        SELECT DISTINCT p.AssetId 
        FROM assoc.Payments p
        LEFT JOIN corp.Users cu ON p.UserId = cu.UserId
        LEFT JOIN assoc.Users au ON p.UserId = au.UserId AND p.TenantId = @TenantId
        WHERE (
                (@UserEmail IS NOT NULL AND (cu.Email = @UserEmail OR au.Email = @UserEmail))
                OR p.UserId = @UserId -- Fallback to direct ID match
              )
          AND p.TenantId = @TenantId 
          AND p.AssociationId = @AssociationId
          AND p.AssetId IS NOT NULL
          AND p.AssetId NOT IN (SELECT AssetId FROM @Assets);
    END

    -- 2. Final Sum from the Transaction Ledger
    -- We sum all 'Credits' (Deposits) and subtract all 'Debits' (Settlements/Refunds)
    SELECT ISNULL(SUM(CASE 
        -- Credits: Any successful payment or advance not linked to a generic invoice
        WHEN t.Type = 'Credit' 
             AND (t.Category IN ('Advance Payment', 'Payment')) 
             AND (t.InvoiceId IS NULL OR t.InvoiceId = 0) 
        THEN t.Amount
        
        -- Debits: Any internal credit movement out of the wallet
        WHEN t.Type = 'Debit' 
             AND t.Category IN ('Credit Settlement', 'Internal Credit Transfer') 
        THEN -t.Amount
        
        ELSE 0 
    END), 0)
    FROM assoc.Transactions t
    WHERE t.AssetId IN (SELECT AssetId FROM @Assets)
      AND t.TenantId = @TenantId
      AND t.AssociationId = @AssociationId;
END