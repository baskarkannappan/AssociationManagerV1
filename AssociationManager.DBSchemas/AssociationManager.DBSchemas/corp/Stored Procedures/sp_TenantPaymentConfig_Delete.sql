-- Delete Payment Config
CREATE   PROCEDURE corp.sp_TenantPaymentConfig_Delete
    @Id INT
AS
BEGIN
    SET NOCOUNT ON;
    DELETE FROM corp.TenantPaymentConfig WHERE Id = @Id;
END;