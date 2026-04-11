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
