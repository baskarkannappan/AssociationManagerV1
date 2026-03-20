/*
    Script 0019: Association Subscription View
    Updates association procedures to include current subscription plan name.
*/

GO
CREATE OR ALTER PROCEDURE sp_Associations_GetAllByTenantId
    @TenantId INT
AS
BEGIN
    SELECT a.*, p.Name as PlanName
    FROM Associations a
    LEFT JOIN AssociationSubscriptions s ON a.AssociationId = s.AssociationId
    LEFT JOIN SubscriptionPlans p ON s.PlanId = p.PlanId
    WHERE a.TenantId = @TenantId;
END
GO

CREATE OR ALTER PROCEDURE sp_Associations_GetById
    @Id INT,
    @TenantId INT
AS
BEGIN
    SELECT a.*, p.Name as PlanName
    FROM Associations a
    LEFT JOIN AssociationSubscriptions s ON a.AssociationId = s.AssociationId
    LEFT JOIN SubscriptionPlans p ON s.PlanId = p.PlanId
    WHERE a.AssociationId = @Id AND a.TenantId = @TenantId;
END
GO

CREATE OR ALTER PROCEDURE sp_Associations_GetByUserId
    @UserId INT
AS
BEGIN
    SELECT a.*, p.Name as PlanName
    FROM Associations a
    INNER JOIN UserAssociations ua ON a.TenantId = ua.TenantId
    LEFT JOIN AssociationSubscriptions s ON a.AssociationId = s.AssociationId
    LEFT JOIN SubscriptionPlans p ON s.PlanId = p.PlanId
    WHERE ua.UserId = @UserId;
END
GO
