-- Script0068_RazorpayStoredProcedures.sql
-- Migrating remaining hardcoded SQL in RazorpayRepository to Stored Procedures

-- 1. Procedure for GetOrdersByInvoiceIdAsync
CREATE   PROCEDURE assoc.sp_PaymentOrders_GetByInvoiceId
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