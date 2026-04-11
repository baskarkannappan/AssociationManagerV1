-- Script0112_AuditLogArchivalInfrastructure.sql
-- Creates the archive schema and infrastructure for moving older audit data to keep active tables lean.

-- 1. Create Archive Schema if it doesn't exist
IF NOT EXISTS (SELECT * FROM sys.schemas WHERE name = 'archive')
BEGIN
    EXEC('CREATE SCHEMA [archive]')
END
GO

-- 2. Create archive.AuditLogs mirrored table
-- Note: We omit foreign keys to master tables to prevent historical logs from blocking master data deletion.
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID('archive.AuditLogs') AND type in (N'U'))
BEGIN
    CREATE TABLE [archive].[AuditLogs] (
        [AuditLogId]    INT            NOT NULL,
        [TenantId]      INT            NOT NULL,
        [UserId]        INT            NULL,
        [Action]        NVARCHAR (MAX) NOT NULL,
        [Entity]        NVARCHAR (100) NULL,
        [EntityId]      INT            NULL,
        [IpAddress]     NVARCHAR (50)  NULL,
        [Timestamp]     DATETIME       NOT NULL,
        [AssociationId] INT            NULL,
        [AssetId]       INT            NULL,
        [CorrelationId] NVARCHAR (100) NULL,
        PRIMARY KEY CLUSTERED ([AuditLogId] ASC)
    );
END
GO

-- 3. Create Maintenance Procedure for Archiving
-- Moves data older than @RetentionDays to the archive schema in batches.
IF EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID('corp.sp_Maintenance_ArchiveAuditLogs') AND type in (N'P', N'PC'))
BEGIN
    DROP PROCEDURE corp.sp_Maintenance_ArchiveAuditLogs;
END
GO

CREATE PROCEDURE corp.sp_Maintenance_ArchiveAuditLogs
    @RetentionDays INT = 180, -- Default 6 months
    @BatchSize INT = 5000     -- Limit per run to avoid log bloat
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @CutoffDate DATETIME = DATEADD(DAY, -@RetentionDays, GETUTCDATE());
    DECLARE @RowsAffected INT = 0;

    -- Create temporary table for IDs to be moved (to minimize locking during the move)
    CREATE TABLE #LogsToMove (AuditLogId INT PRIMARY KEY);

    INSERT INTO #LogsToMove (AuditLogId)
    SELECT TOP (@BatchSize) AuditLogId
    FROM corp.AuditLogs WITH (NOLOCK)
    WHERE Timestamp < @CutoffDate
    ORDER BY Timestamp ASC;

    SET @RowsAffected = @@ROWCOUNT;

    IF @RowsAffected > 0
    BEGIN
        BEGIN TRANSACTION;
        BEGIN TRY
            -- 1. Insert into Archive
            INSERT INTO archive.AuditLogs (AuditLogId, TenantId, UserId, Action, Entity, EntityId, IpAddress, Timestamp, AssociationId, AssetId, CorrelationId)
            SELECT l.AuditLogId, l.TenantId, l.UserId, l.Action, l.Entity, l.EntityId, l.IpAddress, l.Timestamp, l.AssociationId, l.AssetId, l.CorrelationId
            FROM corp.AuditLogs l
            INNER JOIN #LogsToMove m ON l.AuditLogId = m.AuditLogId;

            -- 2. Delete from Active
            DELETE l
            FROM corp.AuditLogs l
            INNER JOIN #LogsToMove m ON l.AuditLogId = m.AuditLogId;

            COMMIT TRANSACTION;
            
            PRINT 'Archived ' + CAST(@RowsAffected AS VARCHAR) + ' audit logs.';
        END TRY
        BEGIN CATCH
            ROLLBACK TRANSACTION;
            THROW;
        END CATCH
    END

    DROP TABLE #LogsToMove;
    SELECT @RowsAffected AS ArchivedCount;
END
GO
