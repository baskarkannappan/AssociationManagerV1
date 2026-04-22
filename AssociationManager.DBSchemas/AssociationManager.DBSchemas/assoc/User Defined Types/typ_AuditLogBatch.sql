CREATE TYPE [assoc].[typ_AuditLogBatch] AS TABLE (
    [AssetId]   INT            NULL,
    [Action]    NVARCHAR (MAX) NULL,
    [Entity]    NVARCHAR (100) NULL,
    [EntityId]  INT            NULL,
    [Timestamp] DATETIME       NULL);

