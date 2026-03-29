-- 2. Update sp_AuditLogs_Create to handle AssetId
CREATE   PROCEDURE corp.sp_AuditLogs_Create
    @TenantId INT,
    @AssociationId INT,
    @UserId INT = NULL,
    @AssetId INT = NULL,
    @Action NVARCHAR(MAX),
    @Entity NVARCHAR(100) = NULL,
    @EntityId INT = NULL,
    @IpAddress NVARCHAR(50) = NULL,
    @Timestamp DATETIME
AS
BEGIN
    INSERT INTO corp.AuditLogs (TenantId, AssociationId, UserId, AssetId, Action, Entity, EntityId, IpAddress, Timestamp)
    VALUES (@TenantId, @AssociationId, @UserId, @AssetId, @Action, @Entity, @EntityId, @IpAddress, @Timestamp);
    
    SELECT SCOPE_IDENTITY();
END