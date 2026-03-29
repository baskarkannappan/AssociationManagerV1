CREATE   PROCEDURE corp.sp_PlatformInvoices_GetByAssociationId
    @AssociationId INT
AS
BEGIN
    SELECT pi.*, sp.Name as PlanName
    FROM corp.PlatformInvoices pi
    JOIN corp.SubscriptionPlans sp ON pi.PlanId = sp.PlanId
    WHERE pi.AssociationId = @AssociationId
    ORDER BY pi.BillingDate DESC;
END;