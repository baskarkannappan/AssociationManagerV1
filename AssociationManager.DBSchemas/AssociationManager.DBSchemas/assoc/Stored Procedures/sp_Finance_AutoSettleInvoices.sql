
-- 2. Auto-Settlement Procedure
-- This checks if a Unit has credit and applies it to Unpaid Invoices
CREATE   PROCEDURE assoc.sp_Finance_AutoSettleInvoices
    @AssetId INT,
    @TenantId INT,
    @AssociationId INT,
    @UserId INT -- The user performing or triggering the settlement
AS
BEGIN
    SET NOCOUNT ON;
    
    DECLARE @AvailableCredit DECIMAL(18,2);
    
    -- Get current net balance. We only proceed if it's negative (meaning credit exists).
    SELECT @AvailableCredit = -IsNull(SUM(CASE WHEN Type = 'Debit' THEN Amount ELSE -Amount END), 0)
    FROM assoc.Transactions
    WHERE AssetId = @AssetId 
    AND TenantId = @TenantId 
    AND AssociationId = @AssociationId
    AND Category != 'Credit Settlement';

    IF @AvailableCredit <= 0
        RETURN;

    -- Cursor to loop through Unpaid/Partial Invoices for this Asset
    DECLARE @InvoiceId INT;
    DECLARE @AmountDue DECIMAL(18,2);
    
    DECLARE InvoiceCursor CURSOR FOR 
    SELECT InvoiceId, Amount
    FROM assoc.Invoices
    WHERE AssetId = @AssetId 
    AND TenantId = @TenantId 
    AND AssociationId = @AssociationId
    AND Status IN ('Unpaid', 'Partial')
    ORDER BY DueDate ASC; -- Pay oldest first

    OPEN InvoiceCursor;
    FETCH NEXT FROM InvoiceCursor INTO @InvoiceId, @AmountDue;

    WHILE @@FETCH_STATUS = 0 AND @AvailableCredit > 0
    BEGIN
        DECLARE @SettlementAmount DECIMAL(18,2);
        
        -- How much can we pay?
        IF @AvailableCredit >= @AmountDue
            SET @SettlementAmount = @AmountDue;
        ELSE
            SET @SettlementAmount = @AvailableCredit;

        -- 1. Record the Payment record (Internal Settlement)
        INSERT INTO assoc.Payments (TenantId, AssociationId, AssetId, UserId, InvoiceId, Amount, Currency, Status, CreatedDate, Notes)
        VALUES (@TenantId, @AssociationId, @AssetId, @UserId, @InvoiceId, @SettlementAmount, 'INR', 'Completed', GETUTCDATE(), 'Auto-Settled via Advance Credit');
        
        DECLARE @NewPaymentId INT = SCOPE_IDENTITY();

        -- 2. Record the Ledger Transaction (Credit)
        INSERT INTO assoc.Transactions (TenantId, AssetId, AssociationId, InvoiceId, PaymentId, Type, Amount, Category, Description, TransactionDate)
        VALUES (@TenantId, @AssetId, @AssociationId, @InvoiceId, @NewPaymentId, 'Credit', @SettlementAmount, 'Credit Settlement', 'Auto-Deduction from Advance', GETUTCDATE());

        -- 3. Update Invoice Status
        IF @SettlementAmount >= @AmountDue
            UPDATE assoc.Invoices SET Status = 'Paid' WHERE InvoiceId = @InvoiceId;
        ELSE
            UPDATE assoc.Invoices SET Status = 'Unpaid' WHERE InvoiceId = @InvoiceId;

        -- Reduce available credit for next iteration
        SET @AvailableCredit = @AvailableCredit - @SettlementAmount;
        
        FETCH NEXT FROM InvoiceCursor INTO @InvoiceId, @AmountDue;
    END

    CLOSE InvoiceCursor;
    DEALLOCATE InvoiceCursor;
END;