-- Upsert Payment Config
CREATE   PROCEDURE corp.sp_TenantPaymentConfig_Upsert
    @Id INT = 0,
    @TenantId INT,
    @RazorpayKeyId NVARCHAR(100),
    @RazorpayKeySecret NVARCHAR(100),
    @RazorpayWebhookSecret NVARCHAR(100) = NULL,
    @IsActive BIT = 1
AS
BEGIN
    SET NOCOUNT ON;
    IF EXISTS (SELECT 1 FROM corp.TenantPaymentConfig WHERE Id = @Id OR TenantId = @TenantId)
    BEGIN
        UPDATE corp.TenantPaymentConfig
        SET 
            RazorpayKeyId = @RazorpayKeyId,
            RazorpayKeySecret = @RazorpayKeySecret,
            RazorpayWebhookSecret = @RazorpayWebhookSecret,
            IsActive = @IsActive,
            LastUpdated = GETUTCDATE()
        WHERE Id = @Id OR TenantId = @TenantId;
        
        -- Return the ID
        SELECT ISNULL(NULLIF(@Id, 0), (SELECT Id FROM corp.TenantPaymentConfig WHERE TenantId = @TenantId));
    END
    ELSE
    BEGIN
        INSERT INTO corp.TenantPaymentConfig (TenantId, RazorpayKeyId, RazorpayKeySecret, RazorpayWebhookSecret, IsActive, LastUpdated)
        VALUES (@TenantId, @RazorpayKeyId, @RazorpayKeySecret, @RazorpayWebhookSecret, @IsActive, GETUTCDATE());
        
        SELECT SCOPE_IDENTITY();
    END
END;