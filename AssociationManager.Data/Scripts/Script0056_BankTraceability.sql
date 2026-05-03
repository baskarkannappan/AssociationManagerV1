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
    @AssetId INT = NULL,
    @Receipt NVARCHAR(255) = NULL,
    @PrimaryAccountName NVARCHAR(255) = NULL,
    @PrimaryAccountNumber NVARCHAR(255) = NULL
AS
BEGIN
    INSERT INTO assoc.PaymentOrders (TenantId, AssociationId, UserId, RazorpayOrderId, Amount, Currency, InvoiceId, AssetId, Receipt, PrimaryAccountName, PrimaryAccountNumber)
    VALUES (@TenantId, @AssociationId, @UserId, @RazorpayOrderId, @Amount, @Currency, @InvoiceId, @AssetId, @Receipt, @PrimaryAccountName, @PrimaryAccountNumber);
    
    SELECT SCOPE_IDENTITY();
END
GO

CREATE OR ALTER PROCEDURE assoc.sp_PaymentTransactions_Create
    @TenantId INT,
    @AssociationId INT,
    @PaymentOrderId INT = NULL,
    @RazorpayPaymentId NVARCHAR(255),
    @RazorpayOrderId NVARCHAR(255),
    @RazorpaySignature NVARCHAR(MAX),
    @Status NVARCHAR(50),
    @Amount DECIMAL(18,2),
    @RawResponse NVARCHAR(MAX) = NULL,
    @PrimaryAccountName NVARCHAR(255) = NULL,
    @PrimaryAccountNumber NVARCHAR(255) = NULL,
    @PaymentMethod NVARCHAR(50) = NULL,
    @BankName NVARCHAR(255) = NULL,
    @BankRrn NVARCHAR(255) = NULL,
    @CardNetwork NVARCHAR(50) = NULL,
    @GatewayFee DECIMAL(18,2) = NULL,
    @GatewayTax DECIMAL(18,2) = NULL
AS
BEGIN
    INSERT INTO assoc.PaymentTransactions (TenantId, AssociationId, PaymentOrderId, RazorpayPaymentId, RazorpayOrderId, RazorpaySignature, Status, Amount, RawResponse, PrimaryAccountName, PrimaryAccountNumber, PaymentMethod, BankName, BankRrn, CardNetwork, GatewayFee, GatewayTax)
    VALUES (@TenantId, @AssociationId, @PaymentOrderId, @RazorpayPaymentId, @RazorpayOrderId, @RazorpaySignature, @Status, @Amount, @RawResponse, @PrimaryAccountName, @PrimaryAccountNumber, @PaymentMethod, @BankName, @BankRrn, @CardNetwork, @GatewayFee, @GatewayTax);
    
    SELECT SCOPE_IDENTITY();
END
GO

CREATE OR ALTER PROCEDURE assoc.sp_PaymentTransactions_GetByInvoiceId
    @InvoiceId INT,
    @TenantId INT
AS
BEGIN
    SELECT 
        pt.*, 
        po.InvoiceId,
        po.Status AS OrderStatus
    FROM assoc.PaymentTransactions pt
    JOIN assoc.PaymentOrders po ON pt.PaymentOrderId = po.Id
    WHERE po.InvoiceId = @InvoiceId AND po.TenantId = @TenantId
    ORDER BY pt.CreatedDate DESC;
END
GO

