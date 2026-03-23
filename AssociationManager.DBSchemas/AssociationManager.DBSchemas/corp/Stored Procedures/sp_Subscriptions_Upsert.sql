CREATE   PROCEDURE corp.sp_Subscriptions_Upsert @AssociationId INT, @PlanId INT, @Status NVARCHAR(50), @NextBillingDate DATETIME AS 
BEGIN
    IF EXISTS (SELECT 1 FROM corp.AssociationSubscriptions WHERE AssociationId = @AssociationId)
        UPDATE corp.AssociationSubscriptions SET PlanId = @PlanId, Status = @Status, NextBillingDate = @NextBillingDate WHERE AssociationId = @AssociationId
    ELSE
        INSERT INTO corp.AssociationSubscriptions (AssociationId, PlanId, Status, NextBillingDate) VALUES (@AssociationId, @PlanId, @Status, @NextBillingDate);
END