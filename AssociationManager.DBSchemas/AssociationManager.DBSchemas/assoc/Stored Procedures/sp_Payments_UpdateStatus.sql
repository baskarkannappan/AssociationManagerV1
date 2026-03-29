CREATE   PROCEDURE assoc.sp_Payments_UpdateStatus @Id INT, @Status NVARCHAR(50), @GatewayReference NVARCHAR(255) = NULL, @TenantId INT, @AssociationId INT AS 
BEGIN 
    UPDATE assoc.Payments SET Status = @Status, GatewayReference = @GatewayReference 
    WHERE PaymentId = @Id AND AssociationId = @AssociationId; 
END