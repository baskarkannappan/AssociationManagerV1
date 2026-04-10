-- Script0109_AddAuditLogCorrelationId.sql
-- Adds CorrelationId column to AuditLogs and updates the creation stored procedure.

-- 1. Add CorrelationId to corp.AuditLogs if it doesn't exist
IF NOT EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID('corp.AuditLogs') AND name = 'CorrelationId')
BEGIN
    ALTER TABLE corp.AuditLogs ADD CorrelationId NVARCHAR(100) NULL;
END
GO

-- 2. Add CorrelationId to assoc.AuditLogs if it exists (for redundancy)
IF EXISTS (SELECT * FROM sys.tables t JOIN sys.schemas s ON t.schema_id = s.schema_id WHERE s.name = 'assoc' AND t.name = 'AuditLogs')
BEGIN
    IF NOT EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID('assoc.AuditLogs') AND name = 'CorrelationId')
    BEGIN
        ALTER TABLE assoc.AuditLogs ADD CorrelationId NVARCHAR(100) NULL;
    END
END
GO

-- 3. Update corp.sp_AuditLogs_Create to handle CorrelationId
IF EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID('corp.sp_AuditLogs_Create') AND type in (N'P', N'PC'))
BEGIN
    EXEC('ALTER PROCEDURE corp.sp_AuditLogs_Create
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
    END')
END
GO
