-- Script0060_RazorpayInfrastructure.sql
-- Restoring missing Razorpay database infrastructure (Tables & Stored Procedures)

-- 1. corp.TenantPaymentConfig Table
IF NOT EXISTS (SELECT * FROM sys.tables WHERE schema_id = SCHEMA_ID('corp') AND name = 'TenantPaymentConfig')
BEGIN
    CREATE TABLE corp.TenantPaymentConfig (
        TenantId INT PRIMARY KEY,
        RazorpayKeyId NVARCHAR(255) NOT NULL,
        RazorpayKeySecret NVARCHAR(255) NOT NULL,
        RazorpayWebhookSecret NVARCHAR(255) NULL,
        IsActive BIT NOT NULL DEFAULT 1,
        CreatedDate DATETIME NOT NULL DEFAULT GETDATE(),
        CONSTRAINT FK_TenantPaymentConfig_Tenants FOREIGN KEY (TenantId) REFERENCES corp.Tenants(TenantId)
    );
END
GO

-- 2. assoc.PaymentOrders Table
IF NOT EXISTS (SELECT * FROM sys.tables WHERE schema_id = SCHEMA_ID('assoc') AND name = 'PaymentOrders')
BEGIN
    CREATE TABLE assoc.PaymentOrders (
        Id INT IDENTITY(1,1) PRIMARY KEY,
        TenantId INT NOT NULL,
        AssociationId INT NOT NULL,
        UserId INT NOT NULL,
        RazorpayOrderId NVARCHAR(255) NOT NULL,
        Amount DECIMAL(18,2) NOT NULL,
        Currency NVARCHAR(10) NOT NULL DEFAULT 'INR',
        Status NVARCHAR(50) NOT NULL DEFAULT 'Created',
        InvoiceId INT NULL,
        Receipt NVARCHAR(255) NULL,
        PrimaryAccountName NVARCHAR(255) NULL,
        PrimaryAccountNumber NVARCHAR(255) NULL,
        CreatedDate DATETIME NOT NULL DEFAULT GETDATE(),
        CONSTRAINT FK_PaymentOrders_Associations FOREIGN KEY (AssociationId) REFERENCES corp.Associations(AssociationId)
    );
END
GO

-- 3. assoc.PaymentTransactions Table
IF NOT EXISTS (SELECT * FROM sys.tables WHERE schema_id = SCHEMA_ID('assoc') AND name = 'PaymentTransactions')
BEGIN
    CREATE TABLE assoc.PaymentTransactions (
        Id INT IDENTITY(1,1) PRIMARY KEY,
        TenantId INT NOT NULL,
        AssociationId INT NOT NULL,
        PaymentOrderId INT NULL,
        RazorpayPaymentId NVARCHAR(255) NOT NULL,
        RazorpayOrderId NVARCHAR(255) NOT NULL,
        RazorpaySignature NVARCHAR(MAX) NOT NULL,
        Status NVARCHAR(50) NOT NULL,
        Amount DECIMAL(18,2) NOT NULL,
        RawResponse NVARCHAR(MAX) NULL,
        PrimaryAccountName NVARCHAR(255) NULL,
        PrimaryAccountNumber NVARCHAR(255) NULL,
        PaymentMethod NVARCHAR(50) NULL,
        BankName NVARCHAR(255) NULL,
        BankRrn NVARCHAR(255) NULL,
        CardNetwork NVARCHAR(50) NULL,
        GatewayFee DECIMAL(18,2) NULL,
        GatewayTax DECIMAL(18,2) NULL,
        CreatedDate DATETIME NOT NULL DEFAULT GETDATE(),
        CONSTRAINT FK_PaymentTransactions_Orders FOREIGN KEY (PaymentOrderId) REFERENCES assoc.PaymentOrders(Id)
    );
END
GO

-- 4. assoc.PaymentWebhookLogs Table
IF NOT EXISTS (SELECT * FROM sys.tables WHERE schema_id = SCHEMA_ID('assoc') AND name = 'PaymentWebhookLogs')
BEGIN
    CREATE TABLE assoc.PaymentWebhookLogs (
        Id INT IDENTITY(1,1) PRIMARY KEY,
        TenantId INT NULL,
        EventType NVARCHAR(100) NOT NULL,
        RawPayload NVARCHAR(MAX) NOT NULL,
        Signature NVARCHAR(MAX) NULL,
        IsProcessed BIT NOT NULL DEFAULT 0,
        CreatedDate DATETIME NOT NULL DEFAULT GETDATE()
    );
END
GO

-- 5. Stored Procedures

-- Get Payment Config
CREATE OR ALTER PROCEDURE corp.sp_TenantPaymentConfig_GetByTenantId
    @TenantId INT
AS
BEGIN
    SELECT * FROM corp.TenantPaymentConfig WHERE TenantId = @TenantId AND IsActive = 1;
END;
GO

-- Create Order
CREATE OR ALTER PROCEDURE assoc.sp_PaymentOrders_Create
    @TenantId INT,
    @AssociationId INT,
    @UserId INT,
    @RazorpayOrderId NVARCHAR(255),
    @Amount DECIMAL(18,2),
    @Currency NVARCHAR(10),
    @InvoiceId INT = NULL,
    @Receipt NVARCHAR(255) = NULL,
    @PrimaryAccountName NVARCHAR(255) = NULL,
    @PrimaryAccountNumber NVARCHAR(255) = NULL
AS
BEGIN
    INSERT INTO assoc.PaymentOrders (TenantId, AssociationId, UserId, RazorpayOrderId, Amount, Currency, InvoiceId, Receipt, PrimaryAccountName, PrimaryAccountNumber)
    VALUES (@TenantId, @AssociationId, @UserId, @RazorpayOrderId, @Amount, @Currency, @InvoiceId, @Receipt, @PrimaryAccountName, @PrimaryAccountNumber);
    SELECT SCOPE_IDENTITY();
END;
GO

-- Get Order by Razorpay Id
CREATE OR ALTER PROCEDURE assoc.sp_PaymentOrders_GetByOrderId
    @RazorpayOrderId NVARCHAR(255),
    @TenantId INT
AS
BEGIN
    SELECT * FROM assoc.PaymentOrders WHERE RazorpayOrderId = @RazorpayOrderId AND TenantId = @TenantId;
END;
GO

-- Update Order Status
CREATE OR ALTER PROCEDURE assoc.sp_PaymentOrders_UpdateStatus
    @RazorpayOrderId NVARCHAR(255),
    @Status NVARCHAR(50),
    @TenantId INT
AS
BEGIN
    UPDATE assoc.PaymentOrders
    SET Status = @Status
    WHERE RazorpayOrderId = @RazorpayOrderId AND TenantId = @TenantId;
END;
GO

-- Create Transaction
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
END;
GO

-- Create Webhook Log
CREATE OR ALTER PROCEDURE assoc.sp_PaymentWebhookLogs_Create
    @TenantId INT = NULL,
    @EventType NVARCHAR(100),
    @RawPayload NVARCHAR(MAX),
    @Signature NVARCHAR(MAX) = NULL
AS
BEGIN
    INSERT INTO assoc.PaymentWebhookLogs (TenantId, EventType, RawPayload, Signature)
    VALUES (@TenantId, @EventType, @RawPayload, @Signature);
    SELECT SCOPE_IDENTITY();
END;
GO

-- Get Transactions by Invoice
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
    WHERE po.InvoiceId = @InvoiceId AND po.TenantId = @TenantId;
END;
GO
