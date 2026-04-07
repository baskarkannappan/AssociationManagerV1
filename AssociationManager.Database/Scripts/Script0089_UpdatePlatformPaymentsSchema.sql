-- Script0089_UpdatePlatformPaymentsSchema.sql
-- Updating PlatformPayments table and stored procedure for manual billing

-- 1. Add PaymentMethod and Status columns
IF NOT EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID('corp.PlatformPayments') AND name = 'PaymentMethod')
BEGIN
    ALTER TABLE [corp].[PlatformPayments] ADD [PaymentMethod] NVARCHAR(50) NULL;
END
GO

IF NOT EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID('corp.PlatformPayments') AND name = 'Status')
BEGIN
    ALTER TABLE [corp].[PlatformPayments] ADD [Status] NVARCHAR(50) DEFAULT ('Completed') NOT NULL;
END
GO

-- 2. Update sp_PlatformPayments_Insert to handle new fields
CREATE OR ALTER PROCEDURE corp.sp_PlatformPayments_Insert
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
GO
