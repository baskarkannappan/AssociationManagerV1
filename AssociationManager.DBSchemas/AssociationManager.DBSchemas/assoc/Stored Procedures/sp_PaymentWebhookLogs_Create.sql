-- Create Webhook Log
CREATE   PROCEDURE assoc.sp_PaymentWebhookLogs_Create
    @TenantId INT = NULL,
    @EventType NVARCHAR(100),
    @RawPayload NVARCHAR(MAX),
    @Signature NVARCHAR(MAX) = NULL
AS
BEGIN
    INSERT INTO assoc.PaymentWebhookLogs (TenantId, EventType, RawPayload, Signature)
    VALUES (@TenantId, @EventType, @RawPayload, @Signature);
    SELECT SCOPE_IDENTITY();
END;