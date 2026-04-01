-- 2. Procedure for TransactionExistsAsync
CREATE   PROCEDURE assoc.sp_PaymentTransactions_CheckExists
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