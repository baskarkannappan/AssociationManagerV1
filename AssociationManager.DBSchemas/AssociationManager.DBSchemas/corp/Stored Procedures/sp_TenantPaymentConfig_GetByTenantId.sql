-- 5. Stored Procedures

-- Get Payment Config
CREATE   PROCEDURE corp.sp_TenantPaymentConfig_GetByTenantId
    @TenantId INT
AS
BEGIN
    SELECT * FROM corp.TenantPaymentConfig WHERE TenantId = @TenantId AND IsActive = 1;
END;