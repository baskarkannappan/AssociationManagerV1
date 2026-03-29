CREATE   PROCEDURE assoc.sp_WorkOrders_Delete @Id INT, @TenantId INT, @AssociationId INT AS 
BEGIN 
    DELETE FROM assoc.WorkOrders 
    WHERE WorkOrderId = @Id AND AssociationId = @AssociationId; 
END