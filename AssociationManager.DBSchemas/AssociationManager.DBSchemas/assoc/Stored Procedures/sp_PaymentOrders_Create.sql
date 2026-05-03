
-- 2. Update Stored Procedures
CREATE   PROCEDURE assoc.sp_PaymentOrders_Create
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