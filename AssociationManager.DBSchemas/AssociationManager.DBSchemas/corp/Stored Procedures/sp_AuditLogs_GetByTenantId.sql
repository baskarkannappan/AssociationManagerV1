-- AUDIT
CREATE   PROCEDURE corp.sp_AuditLogs_GetByTenantId @TenantId INT, @AssociationId INT AS 
BEGIN 
    SELECT * FROM corp.AuditLogs 
    WHERE AssociationId = @AssociationId 
    ORDER BY Timestamp DESC; 
END