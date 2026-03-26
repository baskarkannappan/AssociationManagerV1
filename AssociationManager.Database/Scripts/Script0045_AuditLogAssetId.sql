-- Script0045_AuditLogAssetId.sql
-- Adds AssetId to AuditLogs to support per-asset introspection of billing and other actions

-- 1. Add AssetId column to corp.AuditLogs
IF NOT EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID('corp.AuditLogs') AND name = 'AssetId')
BEGIN
    ALTER TABLE corp.AuditLogs ADD AssetId INT NULL;
    ALTER TABLE corp.AuditLogs ADD CONSTRAINT FK_AuditLogs_Assets FOREIGN KEY (AssetId) REFERENCES assoc.Assets(AssetId);
END
GO

-- 2. Update sp_AuditLogs_Create to handle AssetId
CREATE OR ALTER PROCEDURE corp.sp_AuditLogs_Create
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
GO

-- 3. Create sp_AuditLogs_GetByAssetId
CREATE OR ALTER PROCEDURE assoc.sp_AuditLogs_GetByAssetId
    @AssetId INT,
    @TenantId INT,
    @AssociationId INT
AS
BEGIN
    SELECT * 
    FROM corp.AuditLogs 
    WHERE AssetId = @AssetId 
      AND TenantId = @TenantId 
      AND AssociationId = @AssociationId
    ORDER BY Timestamp DESC;
END
GO
