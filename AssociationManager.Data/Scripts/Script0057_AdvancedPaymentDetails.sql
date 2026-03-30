-- Migration Script for Advanced Payment Details
USE AssociationManagerV1;
GO

-- 1. Alter Tables
IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_SCHEMA = 'assoc' AND TABLE_NAME = 'PaymentTransactions' AND COLUMN_NAME = 'PaymentMethod')
BEGIN
    ALTER TABLE assoc.PaymentTransactions ADD PaymentMethod NVARCHAR(50) NULL;
    ALTER TABLE assoc.PaymentTransactions ADD BankName NVARCHAR(100) NULL;
    ALTER TABLE assoc.PaymentTransactions ADD BankRrn NVARCHAR(100) NULL;
    ALTER TABLE assoc.PaymentTransactions ADD CardNetwork NVARCHAR(50) NULL;
    ALTER TABLE assoc.PaymentTransactions ADD GatewayFee DECIMAL(18,2) NULL;
    ALTER TABLE assoc.PaymentTransactions ADD GatewayTax DECIMAL(18,2) NULL;
END
GO

-- 2. Update Stored Procedures
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
    @PrimaryAccountNumber NVARCHAR(100) = NULL,
    @PaymentMethod NVARCHAR(50) = NULL,
    @BankName NVARCHAR(100) = NULL,
    @BankRrn NVARCHAR(100) = NULL,
    @CardNetwork NVARCHAR(50) = NULL,
    @GatewayFee DECIMAL(18,2) = NULL,
    @GatewayTax DECIMAL(18,2) = NULL
AS
BEGIN
    INSERT INTO assoc.PaymentTransactions (
        TenantId, AssociationId, PaymentOrderId, RazorpayPaymentId, RazorpayOrderId, RazorpaySignature, 
        Status, Amount, RawResponse, PrimaryAccountName, PrimaryAccountNumber,
        PaymentMethod, BankName, BankRrn, CardNetwork, GatewayFee, GatewayTax
    )
    VALUES (
        @TenantId, @AssociationId, @PaymentOrderId, @RazorpayPaymentId, @RazorpayOrderId, @RazorpaySignature, 
        @Status, @Amount, @RawResponse, @PrimaryAccountName, @PrimaryAccountNumber,
        @PaymentMethod, @BankName, @BankRrn, @CardNetwork, @GatewayFee, @GatewayTax
    );
    
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
        PT.PrimaryAccountNumber,
        PT.PaymentMethod,
        PT.BankName,
        PT.BankRrn,
        PT.CardNetwork,
        PT.GatewayFee,
        PT.GatewayTax
    FROM assoc.PaymentTransactions PT
    INNER JOIN assoc.PaymentOrders PO ON PT.PaymentOrderId = PO.Id
    WHERE PO.InvoiceId = @InvoiceId
    AND PT.TenantId = @TenantId
    ORDER BY PT.CreatedDate DESC;
END
GO
