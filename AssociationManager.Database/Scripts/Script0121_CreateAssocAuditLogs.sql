-- Script0121_CreateAssocAuditLogs.sql
-- Goal: Create assoc.AuditLogs table and update SPs to use it for association-level auditing

IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[assoc].[AuditLogs]') AND type in (N'U'))
BEGIN
    PRINT 'Creating assoc.AuditLogs table...';
    CREATE TABLE [assoc].[AuditLogs] (
        [AuditLogId]    INT            IDENTITY (1, 1) NOT NULL,
        [TenantId]      INT            NOT NULL,
        [UserId]        INT            NULL,
        [Action]        NVARCHAR (200) NOT NULL,
        [Entity]        NVARCHAR (200) NULL,
        [EntityId]      INT            NULL,
        [IpAddress]     NVARCHAR (100) NULL,
        [Timestamp]     DATETIME       DEFAULT (getdate()) NOT NULL,
        [AssociationId] INT            NOT NULL,
        [AssetId]       INT            NULL,
        [CorrelationId] NVARCHAR (100) NULL,
        PRIMARY KEY CLUSTERED ([AuditLogId] ASC),
        CONSTRAINT [FK_AuditLogs_Assoc_Assets] FOREIGN KEY ([AssetId]) REFERENCES [assoc].[Assets] ([AssetId]),
        CONSTRAINT [FK_AuditLogs_Assoc_Associations] FOREIGN KEY ([AssociationId]) REFERENCES [corp].[Associations] ([AssociationId]),
        CONSTRAINT [FK_AuditLogs_Assoc_Tenants] FOREIGN KEY ([TenantId]) REFERENCES [corp].[Tenants] ([TenantId])
    );

    CREATE NONCLUSTERED INDEX [IX_AuditLogs_Assoc_AssociationId] ON [assoc].[AuditLogs]([AssociationId] ASC);
    CREATE NONCLUSTERED INDEX [IX_AuditLogs_Assoc_Timestamp] ON [assoc].[AuditLogs]([Timestamp] DESC);
    CREATE NONCLUSTERED INDEX [IX_AuditLogs_Assoc_AssetId] ON [assoc].[AuditLogs]([AssetId] ASC);
    CREATE NONCLUSTERED INDEX [IX_AuditLogs_Assoc_TenantId] ON [assoc].[AuditLogs]([TenantId] ASC);
END
GO

PRINT 'Redefining assoc.sp_AuditLogs_CreateBulk to use assoc.AuditLogs...';
GO
CREATE OR ALTER PROCEDURE [assoc].[sp_AuditLogs_CreateBulk]
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
GO

PRINT 'Redefining assoc.sp_AuditLogs_GetByAssetId to use assoc.AuditLogs...';
GO
CREATE OR ALTER PROCEDURE assoc.sp_AuditLogs_GetByAssetId @AssetId INT, @TenantId INT, @AssociationId INT AS 
BEGIN 
    SELECT * FROM assoc.AuditLogs 
    WHERE AssetId = @AssetId AND AssociationId = @AssociationId 
    ORDER BY Timestamp DESC; 
END
GO

PRINT 'Script0121 completed successfully.';
