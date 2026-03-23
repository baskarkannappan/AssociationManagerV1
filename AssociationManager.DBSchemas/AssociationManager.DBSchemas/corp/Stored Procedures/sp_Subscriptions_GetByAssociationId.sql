CREATE   PROCEDURE corp.sp_Subscriptions_GetByAssociationId @AssociationId INT AS 
BEGIN
    SELECT s.*, a.TenantId, a.Name as AssociationName, p.Name as PlanName, p.BasePrice, p.PricePerAsset
    FROM corp.AssociationSubscriptions s
    JOIN corp.SubscriptionPlans p ON s.PlanId = p.PlanId
    JOIN corp.Associations a ON s.AssociationId = a.AssociationId
    WHERE s.AssociationId = @AssociationId;
END