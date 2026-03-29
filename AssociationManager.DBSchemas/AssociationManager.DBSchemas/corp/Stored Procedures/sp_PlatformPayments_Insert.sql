CREATE   PROCEDURE corp.sp_PlatformPayments_Insert
    @PlatformInvoiceId INT,
    @Amount DECIMAL(18,2),
    @TransactionRef NVARCHAR(255)
AS
BEGIN
    BEGIN TRANSACTION;
    
    INSERT INTO corp.PlatformPayments (PlatformInvoiceId, Amount, TransactionRef)
    VALUES (@PlatformInvoiceId, @Amount, @TransactionRef);
    
    UPDATE corp.PlatformInvoices 
    SET Status = 'Paid' 
    WHERE PlatformInvoiceId = @PlatformInvoiceId;
    
    COMMIT TRANSACTION;
    SELECT SCOPE_IDENTITY();
END;