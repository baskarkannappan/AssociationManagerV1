-- Restore Razorpay Configuration for Tenant 1
IF NOT EXISTS (SELECT 1 FROM corp.TenantPaymentConfig WHERE TenantId = 1)
BEGIN
    INSERT INTO corp.TenantPaymentConfig (TenantId, RazorpayKeyId, RazorpayKeySecret, IsActive)
    VALUES (1, 'rzp_test_SWtZ26EZdULbQy', 'V0f3PBqMcmMEvBIRcx7LIdo7', 1);
    
    PRINT 'Razorpay Configuration restored for Tenant 1.';
END
ELSE
BEGIN
    UPDATE corp.TenantPaymentConfig
    SET RazorpayKeyId = 'rzp_test_SWtZ26EZdULbQy',
        RazorpayKeySecret = 'V0f3PBqMcmMEvBIRcx7LIdo7',
        IsActive = 1
    WHERE TenantId = 1;

    PRINT 'Razorpay Configuration updated for Tenant 1.';
END
GO
