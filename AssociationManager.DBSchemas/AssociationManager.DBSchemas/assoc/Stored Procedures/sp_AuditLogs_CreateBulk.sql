CREATE   PROCEDURE [assoc].[sp_AuditLogs_CreateBulk]
    @TenantId INT,
    @AssociationId INT,
    @UserId INT,
    @Logs [assoc].[typ_AuditLogBatch] READONLY
AS
BEGIN
    SET NOCOUNT ON;

    INSERT INTO [assoc].[AuditLogs] (TenantId, AssociationId, UserId, AssetId, Action, Entity, EntityId, Timestamp)
    SELECT @TenantId, @AssociationId, @UserId, AssetId, Action, Entity, EntityId, Timestamp
    FROM @Logs;
END