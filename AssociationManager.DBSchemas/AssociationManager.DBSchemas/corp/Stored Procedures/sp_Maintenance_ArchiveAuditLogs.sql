CREATE   PROCEDURE corp.sp_Maintenance_ArchiveAuditLogs
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
