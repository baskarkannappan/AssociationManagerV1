CREATE PROCEDURE corp.sp_AuditLogs_Create
        @TenantId INT,
        @AssociationId INT = NULL,
        @UserId INT = NULL,
        @AssetId INT = NULL,
        @Action NVARCHAR(MAX),
        @Entity NVARCHAR(100) = NULL,
        @EntityId INT = NULL,
        @IpAddress NVARCHAR(50) = NULL,
        @CorrelationId NVARCHAR(100) = NULL,
        @Timestamp DATETIME
    AS
    BEGIN
        INSERT INTO corp.AuditLogs (TenantId, AssociationId, UserId, AssetId, Action, Entity, EntityId, IpAddress, CorrelationId, Timestamp)
        VALUES (@TenantId, @AssociationId, @UserId, @AssetId, @Action, @Entity, @EntityId, @IpAddress, @CorrelationId, @Timestamp);
        
        SELECT SCOPE_IDENTITY();
    END