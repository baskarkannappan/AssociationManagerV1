CREATE PROCEDURE assoc.sp_Payments_Create 
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
    VALUES (@TenantId, @AssociationId, @AssetId, @UserId, @InvoiceId, @Amount, @Currency, @Status, @CreatedDate, @Notes, @GatewayReference); 
    SELECT SCOPE_IDENTITY(); 
END