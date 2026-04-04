-- Get All Payment Configs (Admin Only)
CREATE   PROCEDURE corp.sp_TenantPaymentConfig_GetAll
AS
BEGIN
    SET NOCOUNT ON;
    SELECT 
        c.Id, 
        c.TenantId, 
        t.Name AS TenantName,
        c.RazorpayKeyId, 
        c.RazorpayKeySecret, 
        c.RazorpayWebhookSecret,
        c.IsActive, 
        c.LastUpdated
    FROM corp.TenantPaymentConfig c
    JOIN corp.Tenants t ON c.TenantId = t.TenantId
    ORDER BY c.TenantId;
END;