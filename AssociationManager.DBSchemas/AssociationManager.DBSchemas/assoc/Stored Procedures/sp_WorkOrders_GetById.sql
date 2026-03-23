-- WORK ORDERS
CREATE   PROCEDURE assoc.sp_WorkOrders_GetById @Id INT, @TenantId INT, @AssociationId INT AS 
BEGIN SELECT w.*, a.Name as AssetName FROM assoc.WorkOrders w LEFT JOIN assoc.Assets a ON w.AssetId = a.AssetId WHERE w.WorkOrderId = @Id AND w.TenantId = @TenantId AND w.AssociationId = @AssociationId; END