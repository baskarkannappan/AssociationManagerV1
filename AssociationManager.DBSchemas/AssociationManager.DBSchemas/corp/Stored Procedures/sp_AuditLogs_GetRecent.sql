CREATE PROCEDURE corp.sp_AuditLogs_GetRecent
    @TenantId INT,
    @AssociationId INT,
    @Count INT
AS
BEGIN
    SET NOCOUNT ON;
    SELECT TOP (@Count) * 
    FROM corp.AuditLogs 
    WHERE TenantId = @TenantId AND AssociationId = @AssociationId 
    ORDER BY Timestamp DESC
END
GO
