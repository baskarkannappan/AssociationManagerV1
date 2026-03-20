-- Update sp_Subscriptions_GetByAssociationId to include AssociationName
CREATE OR ALTER PROCEDURE sp_Subscriptions_GetByAssociationId
    @AssociationId INT
AS
BEGIN
    SELECT s.*, a.TenantId, a.Name as AssociationName, p.Name as PlanName, p.BasePrice, p.PricePerAsset
    FROM AssociationSubscriptions s
    JOIN SubscriptionPlans p ON s.PlanId = p.PlanId
    JOIN Associations a ON s.AssociationId = a.AssociationId
    WHERE s.AssociationId = @AssociationId;
END
GO
