-- Script0068_RazorpayStoredProcedures.sql
-- Migrating remaining hardcoded SQL in RazorpayRepository to Stored Procedures

-- 1. Procedure for GetOrdersByInvoiceIdAsync
CREATE OR ALTER PROCEDURE assoc.sp_PaymentOrders_GetByInvoiceId
    @InvoiceId INT,
    @TenantId INT
AS
BEGIN
    SET NOCOUNT ON;
    SELECT * 
    FROM assoc.PaymentOrders 
    WHERE InvoiceId = @InvoiceId 
      AND TenantId = @TenantId;
END;
GO

-- 2. Procedure for TransactionExistsAsync
CREATE OR ALTER PROCEDURE assoc.sp_PaymentTransactions_CheckExists
    @RazorpayPaymentId NVARCHAR(255),
    @TenantId INT
AS
BEGIN
    SET NOCOUNT ON;
    SELECT CAST(COUNT(1) AS BIT) 
    FROM assoc.PaymentTransactions 
    WHERE RazorpayPaymentId = @RazorpayPaymentId 
      AND TenantId = @TenantId;
END;
GO
