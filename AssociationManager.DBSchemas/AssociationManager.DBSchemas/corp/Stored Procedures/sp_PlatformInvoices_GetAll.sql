CREATE PROCEDURE [corp].[sp_PlatformInvoices_GetAll]
AS
BEGIN
    SET NOCOUNT ON;

    SELECT 
        pi.*, 
        sp.Name as PlanName, 
        a.Name as AssociationName 
    FROM corp.PlatformInvoices pi 
    JOIN corp.SubscriptionPlans sp ON pi.PlanId = sp.PlanId 
    JOIN corp.Associations a ON pi.AssociationId = a.AssociationId 
    ORDER BY pi.BillingDate DESC
END
GO
