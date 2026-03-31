-- Create Transaction
CREATE   PROCEDURE assoc.sp_PaymentTransactions_Create
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