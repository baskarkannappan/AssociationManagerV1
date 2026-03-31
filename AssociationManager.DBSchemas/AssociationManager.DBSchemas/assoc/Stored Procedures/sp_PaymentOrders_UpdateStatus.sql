-- Update Order Status
CREATE   PROCEDURE assoc.sp_PaymentOrders_UpdateStatus
    @RazorpayOrderId NVARCHAR(255),
    @Status NVARCHAR(50),
    @TenantId INT
AS
BEGIN
    UPDATE assoc.PaymentOrders
    SET Status = @Status
    WHERE RazorpayOrderId = @RazorpayOrderId AND TenantId = @TenantId;
END;