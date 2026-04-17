
-- Update core payment creation to include AssetId, InvoiceId, and Notes
CREATE   PROCEDURE assoc.sp_Payments_Create
    @TenantId INT,
    @AssociationId INT,
    @AssetId INT = NULL,
    @UserId INT = NULL,
    @InvoiceId INT = NULL,
    @Amount DECIMAL(18, 2),
    @Currency NVARCHAR(10),
    @Status NVARCHAR(50),
    @CreatedDate DATETIME,
    @Notes NVARCHAR(500) = NULL,
    @GatewayReference NVARCHAR(255) = NULL
AS 
BEGIN 
    INSERT INTO assoc.Payments (TenantId, AssociationId, AssetId, UserId, InvoiceId, Amount, Currency, Status, CreatedDate, Notes, GatewayReference) 
    OUTPUT INSERTED.PaymentId 
    VALUES (@TenantId, @AssociationId, @AssetId, @UserId, @InvoiceId, @Amount, @Currency, @Status, @CreatedDate, @Notes, @GatewayReference); 
END