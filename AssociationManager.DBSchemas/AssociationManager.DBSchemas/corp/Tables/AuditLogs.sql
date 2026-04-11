CREATE TABLE [corp].[AuditLogs] (
    [AuditLogId]    INT            IDENTITY (1, 1) NOT NULL,
    [TenantId]      INT            NOT NULL,
    [UserId]        INT            NULL,
    [Action]        NVARCHAR (200) NOT NULL,
    [Entity]        NVARCHAR (200) NULL,
    [EntityId]      INT            NULL,
    [IpAddress]     NVARCHAR (100) NULL,
    [Timestamp]     DATETIME       DEFAULT (getdate()) NOT NULL,
    [AssociationId] INT            NULL,
    [AssetId]       INT            NULL,
    [CorrelationId] NVARCHAR (100) NULL,
    PRIMARY KEY CLUSTERED ([AuditLogId] ASC),
    CONSTRAINT [FK_AuditLogs_Assets] FOREIGN KEY ([AssetId]) REFERENCES [assoc].[Assets] ([AssetId]),
    CONSTRAINT [FK_AuditLogs_Associations] FOREIGN KEY ([AssociationId]) REFERENCES [corp].[Associations] ([AssociationId]),
    CONSTRAINT [FK_AuditLogs_Tenants] FOREIGN KEY ([TenantId]) REFERENCES [corp].[Tenants] ([TenantId])
);








GO
CREATE NONCLUSTERED INDEX [IX_AuditLogs_AssociationId]
    ON [corp].[AuditLogs]([AssociationId] ASC);

