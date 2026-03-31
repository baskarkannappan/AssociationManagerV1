-- Get Transactions by Invoice
CREATE   PROCEDURE assoc.sp_PaymentTransactions_GetByInvoiceId
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