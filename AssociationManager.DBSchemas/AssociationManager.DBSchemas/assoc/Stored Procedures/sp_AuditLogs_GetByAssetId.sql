CREATE   PROCEDURE assoc.sp_AuditLogs_GetByAssetId @AssetId INT, @TenantId INT, @AssociationId INT AS 
BEGIN 
    SELECT * FROM corp.AuditLogs 
    WHERE AssetId = @AssetId AND AssociationId = @AssociationId 
    ORDER BY Timestamp DESC; 
END