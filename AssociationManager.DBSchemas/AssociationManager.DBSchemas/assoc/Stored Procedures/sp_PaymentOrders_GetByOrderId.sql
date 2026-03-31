-- Get Order by Razorpay Id
CREATE   PROCEDURE assoc.sp_PaymentOrders_GetByOrderId
    @RazorpayOrderId NVARCHAR(255),
    @TenantId INT
AS
BEGIN
    SELECT * FROM assoc.PaymentOrders WHERE RazorpayOrderId = @RazorpayOrderId AND TenantId = @TenantId;
END;