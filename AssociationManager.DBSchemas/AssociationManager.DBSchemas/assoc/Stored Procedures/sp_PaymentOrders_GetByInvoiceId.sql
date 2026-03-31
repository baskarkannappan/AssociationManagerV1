-- Get all gateway orders for an invoice
CREATE   PROCEDURE assoc.sp_PaymentOrders_GetByInvoiceId
    @InvoiceId INT,
    @TenantId INT
AS
BEGIN
    SELECT *
    FROM assoc.PaymentOrders
    WHERE InvoiceId = @InvoiceId AND TenantId = @TenantId
    ORDER BY CreatedDate DESC;
END;