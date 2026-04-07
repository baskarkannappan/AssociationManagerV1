-- Unified Finance Procedures and Logic Fixes

-- 1. Correct Asset Balance Calculation
-- Fixes the bug where Credit Settlements (Wallet Drains) were ignored, leading to incorrect balance reporting.
CREATE OR ALTER PROCEDURE assoc.sp_Finance_GetAssetBalance
    @AssetId INT,
    @TenantId INT,
    @AssociationId INT
AS
BEGIN
    SET NOCOUNT ON;
    
    -- Negative = Credit (Advance Wallet)
    -- Positive = Debit (Outstanding Debt)
    SELECT IsNull(SUM(CASE WHEN Type = 'Debit' THEN Amount ELSE -Amount END), 0) as CurrentBalance
    FROM assoc.Transactions
    WHERE AssetId = @AssetId 
    AND TenantId = @TenantId 
    AND AssociationId = @AssociationId;
    -- Note: We now INCLUDE all categories (especially Credit Settlement) to ensure accurate spending tracking.
END;
GO

-- 2. Correct Auto-Settlement Procedure
-- Ensures that the available credit is correctly reduced as invoices are paid.
CREATE OR ALTER PROCEDURE assoc.sp_Finance_AutoSettleInvoices
    @AssetId INT,
    @TenantId INT,
    @AssociationId INT,
    @UserId INT
AS
BEGIN
    SET NOCOUNT ON;
    
    DECLARE @AvailableCredit DECIMAL(18,2);
    
    -- Calculate Wallet Power (Negative Balance means Credit exists)
    SELECT @AvailableCredit = -IsNull(SUM(CASE WHEN Type = 'Debit' THEN Amount ELSE -Amount END), 0)
    FROM assoc.Transactions
    WHERE AssetId = @AssetId 
    AND TenantId = @TenantId 
    AND AssociationId = @AssociationId;

    IF @AvailableCredit <= 0
        RETURN;

    -- Cursor to loop through Unpaid Invoices
    DECLARE @InvoiceId INT;
    DECLARE @Principal DECIMAL(18,2);
    
    -- IMPORTANT: We only join on Invoices to get the base Principal. 
    -- Fines will be calculated and settled separately or handled via total amount due logic.
    DECLARE InvoiceCursor CURSOR FOR 
    SELECT InvoiceId, Amount
    FROM assoc.Invoices
    WHERE AssetId = @AssetId 
    AND TenantId = @TenantId 
    AND AssociationId = @AssociationId
    AND Status IN ('Unpaid', 'Partial')
    ORDER BY DueDate ASC;

    OPEN InvoiceCursor;
    FETCH NEXT FROM InvoiceCursor INTO @InvoiceId, @Principal;

    WHILE @@FETCH_STATUS = 0 AND @AvailableCredit > 0
    BEGIN
        DECLARE @TotalDue DECIMAL(18,2);
        
        -- Calculate TRUE TOTAL DUE (Principal + Persisted Line Items)
        SELECT @TotalDue = @Principal + ISNULL(SUM(Amount), 0)
        FROM assoc.InvoiceLineItems
        WHERE InvoiceId = @InvoiceId;

        DECLARE @SettlementAmount DECIMAL(18,2);
        
        -- Determine settlement amount
        IF @AvailableCredit >= @TotalDue
            SET @SettlementAmount = @TotalDue;
        ELSE
            SET @SettlementAmount = @AvailableCredit;

        -- 1. Record the Payment record
        INSERT INTO assoc.Payments (TenantId, AssociationId, AssetId, UserId, InvoiceId, Amount, Currency, Status, CreatedDate, Notes)
        VALUES (@TenantId, @AssociationId, @AssetId, @UserId, @InvoiceId, @SettlementAmount, 'INR', 'Completed', GETUTCDATE(), 'Auto-Settled via Advance Credit');
        
        DECLARE @NewPaymentId INT = SCOPE_IDENTITY();

        -- 2. Record the Ledger Transaction (Credit to Invoice)
        INSERT INTO assoc.Transactions (TenantId, AssetId, AssociationId, InvoiceId, PaymentId, Type, Amount, Category, Description, TransactionDate)
        VALUES (@TenantId, @AssetId, @AssociationId, @InvoiceId, @NewPaymentId, 'Credit', @SettlementAmount, 'Credit Settlement', 'Auto-Deduction from Advance', GETUTCDATE());

        -- 3. Record the Settlement (Debit to Wallet)
        INSERT INTO assoc.Transactions (TenantId, AssetId, AssociationId, InvoiceId, PaymentId, Type, Amount, Category, Description, TransactionDate)
        VALUES (@TenantId, @AssetId, @AssociationId, NULL, @NewPaymentId, 'Debit', @SettlementAmount, 'Credit Settlement', 'Applied to Invoice #' + CAST(@InvoiceId AS VARCHAR), GETUTCDATE());

        -- 4. Update Invoice Status
        IF @SettlementAmount >= @TotalDue
            UPDATE assoc.Invoices SET Status = 'Paid' WHERE InvoiceId = @InvoiceId;
        ELSE
            UPDATE assoc.Invoices SET Status = 'Partial' WHERE InvoiceId = @InvoiceId;

        -- Reduce available credit for next iteration
        SET @AvailableCredit = @AvailableCredit - @SettlementAmount;
        
        FETCH NEXT FROM InvoiceCursor INTO @InvoiceId, @Principal;
    END

    CLOSE InvoiceCursor;
    DEALLOCATE InvoiceCursor;
END;
GO
