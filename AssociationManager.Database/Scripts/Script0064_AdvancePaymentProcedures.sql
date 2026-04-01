-- Support for Advance Payments and Auto-Deduction from Ledger

-- 0. Ensure PaymentOrders table can track AssetId
IF NOT EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID('assoc.PaymentOrders') AND name = 'AssetId')
BEGIN
    ALTER TABLE assoc.PaymentOrders ADD AssetId INT NULL;
    ALTER TABLE assoc.PaymentOrders ADD CONSTRAINT FK_PaymentOrders_Assets FOREIGN KEY (AssetId) REFERENCES assoc.Assets(AssetId);
END
GO

-- Update payment order creation to include AssetId
CREATE OR ALTER PROCEDURE assoc.sp_PaymentOrders_Create
    @TenantId INT,
    @AssociationId INT,
    @UserId INT,
    @RazorpayOrderId NVARCHAR(255),
    @Amount DECIMAL(18,2),
    @Currency NVARCHAR(10),
    @InvoiceId INT = NULL,
    @AssetId INT = NULL,
    @Receipt NVARCHAR(255) = NULL,
    @PrimaryAccountName NVARCHAR(255) = NULL,
    @PrimaryAccountNumber NVARCHAR(255) = NULL
AS
BEGIN
    INSERT INTO assoc.PaymentOrders (TenantId, AssociationId, UserId, RazorpayOrderId, Amount, Currency, InvoiceId, AssetId, Receipt, PrimaryAccountName, PrimaryAccountNumber)
    VALUES (@TenantId, @AssociationId, @UserId, @RazorpayOrderId, @Amount, @Currency, @InvoiceId, @AssetId, @Receipt, @PrimaryAccountName, @PrimaryAccountNumber);
    SELECT SCOPE_IDENTITY();
END;
GO

-- Update core payment creation to include AssetId, InvoiceId, and Notes
CREATE OR ALTER PROCEDURE assoc.sp_Payments_Create
    @TenantId INT,
    @AssociationId INT,
    @AssetId INT = NULL,
    @UserId INT = NULL,
    @InvoiceId INT = NULL,
    @Amount DECIMAL(18, 2),
    @Currency NVARCHAR(10),
    @Status NVARCHAR(50),
    @CreatedDate DATETIME,
    @Notes NVARCHAR(500) = NULL,
    @GatewayReference NVARCHAR(255) = NULL
AS 
BEGIN 
    INSERT INTO assoc.Payments (TenantId, AssociationId, AssetId, UserId, InvoiceId, Amount, Currency, Status, CreatedDate, Notes, GatewayReference) 
    OUTPUT INSERTED.PaymentId 
    VALUES (@TenantId, @AssociationId, @AssetId, @UserId, @InvoiceId, @Amount, @Currency, @Status, @CreatedDate, @Notes, @GatewayReference); 
END
GO

-- 1. Helper to get the current Asset Balance (Outstanding vs Credit)
-- If Balance is negative, it means the user has "Credit" (Advance).
CREATE OR ALTER PROCEDURE assoc.sp_Finance_GetAssetBalance
    @AssetId INT,
    @TenantId INT,
    @AssociationId INT
AS
BEGIN
    SET NOCOUNT ON;
    
    SELECT IsNull(SUM(CASE WHEN Type = 'Debit' THEN Amount ELSE -Amount END), 0) as CurrentBalance
    FROM assoc.Transactions
    WHERE AssetId = @AssetId 
    AND TenantId = @TenantId 
    AND AssociationId = @AssociationId;
END;
GO

-- 2. Auto-Settlement Procedure
-- This checks if a Unit has credit and applies it to Unpaid Invoices
CREATE OR ALTER PROCEDURE assoc.sp_Finance_AutoSettleInvoices
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
    AND AssociationId = @AssociationId;

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
            UPDATE assoc.Invoices SET Status = 'Partial' WHERE InvoiceId = @InvoiceId;

        -- Reduce available credit for next iteration
        SET @AvailableCredit = @AvailableCredit - @SettlementAmount;
        
        FETCH NEXT FROM InvoiceCursor INTO @InvoiceId, @AmountDue;
    END

    CLOSE InvoiceCursor;
    DEALLOCATE InvoiceCursor;
END;
GO
