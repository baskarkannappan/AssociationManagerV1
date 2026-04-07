-- 2. Update sp_PlatformPayments_Insert to handle new fields
CREATE   PROCEDURE corp.sp_PlatformPayments_Insert
    @PlatformInvoiceId INT,
    @Amount DECIMAL(18,2),
    @TransactionRef NVARCHAR(255),
    @PaymentMethod NVARCHAR(50) = 'Manual',
    @Status NVARCHAR(50) = 'Completed'
AS
BEGIN
    BEGIN TRANSACTION;
    
    INSERT INTO corp.PlatformPayments (PlatformInvoiceId, Amount, TransactionRef, PaymentMethod, Status)
    VALUES (@PlatformInvoiceId, @Amount, @TransactionRef, @PaymentMethod, @Status);
    
    -- If status is 'Completed', mark the invoice as Paid. 
    -- If 'Pending Verification', keep it unpaid or add a new invoice status.
    IF @Status = 'Completed'
    BEGIN
        UPDATE corp.PlatformInvoices 
        SET Status = 'Paid' 
        WHERE PlatformInvoiceId = @PlatformInvoiceId;
    END
    ELSE
    BEGIN
        UPDATE corp.PlatformInvoices 
        SET Status = 'Payment Pending' 
        WHERE PlatformInvoiceId = @PlatformInvoiceId;
    END
    
    COMMIT TRANSACTION;
    SELECT SCOPE_IDENTITY();
END;