-- Fixed Migration Script for Bank Traceability
USE AssociationManagerV1;
GO

-- 1. Ensure Columns Exist (Safe Re-run)
IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_SCHEMA = 'assoc' AND TABLE_NAME = 'PaymentOrders' AND COLUMN_NAME = 'PrimaryAccountName')
BEGIN
    ALTER TABLE assoc.PaymentOrders ADD PrimaryAccountName NVARCHAR(200) NULL;
    ALTER TABLE assoc.PaymentOrders ADD PrimaryAccountNumber NVARCHAR(100) NULL;
END
GO

IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_SCHEMA = 'assoc' AND TABLE_NAME = 'PaymentTransactions' AND COLUMN_NAME = 'PrimaryAccountName')
BEGIN
    ALTER TABLE assoc.PaymentTransactions ADD PrimaryAccountName NVARCHAR(200) NULL;
    ALTER TABLE assoc.PaymentTransactions ADD PrimaryAccountNumber NVARCHAR(100) NULL;
END
GO

-- 2. Update Stored Procedures
CREATE OR ALTER PROCEDURE assoc.sp_PaymentOrders_Create
    @TenantId INT,
    @AssociationId INT,
    @UserId INT,
    @RazorpayOrderId NVARCHAR(255),
    @Amount DECIMAL(18,2),
    @Currency NVARCHAR(10),
    @InvoiceId INT = NULL,
    @Receipt NVARCHAR(255) = NULL,
    @PrimaryAccountName NVARCHAR(200) = NULL,
    @PrimaryAccountNumber NVARCHAR(100) = NULL
AS
BEGIN
    INSERT INTO assoc.PaymentOrders (TenantId, AssociationId, UserId, RazorpayOrderId, Amount, Currency, InvoiceId, Receipt, PrimaryAccountName, PrimaryAccountNumber)
    VALUES (@TenantId, @AssociationId, @UserId, @RazorpayOrderId, @Amount, @Currency, @InvoiceId, @Receipt, @PrimaryAccountName, @PrimaryAccountNumber);
    
    SELECT SCOPE_IDENTITY();
END
GO

CREATE OR ALTER PROCEDURE assoc.sp_PaymentTransactions_Create
    @TenantId INT,
    @AssociationId INT,
    @PaymentOrderId INT = NULL,
    @RazorpayPaymentId NVARCHAR(255),
    @RazorpayOrderId NVARCHAR(255),
    @RazorpaySignature NVARCHAR(500),
    @Status NVARCHAR(50),
    @Amount DECIMAL(18,2),
    @RawResponse NVARCHAR(MAX) = NULL,
    @PrimaryAccountName NVARCHAR(200) = NULL,
    @PrimaryAccountNumber NVARCHAR(100) = NULL
AS
BEGIN
    INSERT INTO assoc.PaymentTransactions (TenantId, AssociationId, PaymentOrderId, RazorpayPaymentId, RazorpayOrderId, RazorpaySignature, Status, Amount, RawResponse, PrimaryAccountName, PrimaryAccountNumber)
    VALUES (@TenantId, @AssociationId, @PaymentOrderId, @RazorpayPaymentId, @RazorpayOrderId, @RazorpaySignature, @Status, @Amount, @RawResponse, @PrimaryAccountName, @PrimaryAccountNumber);
    
    SELECT SCOPE_IDENTITY();
END
GO

CREATE OR ALTER PROCEDURE assoc.sp_PaymentTransactions_GetByInvoiceId
    @InvoiceId INT,
    @TenantId INT
AS
BEGIN
    SELECT 
        PT.CreatedDate,
        PT.Amount,
        PT.Status,
        PT.RazorpayPaymentId AS ReferenceId,
        'Gateway' AS Method,
        PT.RazorpayOrderId,
        PT.PrimaryAccountName,
        PT.PrimaryAccountNumber
    FROM assoc.PaymentTransactions PT
    INNER JOIN assoc.PaymentOrders PO ON PT.PaymentOrderId = PO.Id
    WHERE PO.InvoiceId = @InvoiceId
    AND PT.TenantId = @TenantId
    ORDER BY PT.CreatedDate DESC;
END
GO
