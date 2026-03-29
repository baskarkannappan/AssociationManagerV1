-- PAYMENTS
CREATE   PROCEDURE assoc.sp_Payments_GetById @Id INT, @TenantId INT, @AssociationId INT AS 
BEGIN 
    SELECT * FROM assoc.Payments 
    WHERE PaymentId = @Id AND AssociationId = @AssociationId; 
END