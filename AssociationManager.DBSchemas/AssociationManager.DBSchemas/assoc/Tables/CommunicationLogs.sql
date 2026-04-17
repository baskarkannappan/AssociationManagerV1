CREATE TABLE [assoc].[CommunicationLogs] (
    [LogId]          INT            IDENTITY (1, 1) NOT NULL,
    [TenantId]       INT            NOT NULL,
    [AssociationId]  INT            NOT NULL,
    [RecipientEmail] NVARCHAR (255) NOT NULL,
    [RecipientName]  NVARCHAR (255) NULL,
    [Subject]        NVARCHAR (500) NOT NULL,
    [HtmlBody]       NVARCHAR (MAX) NOT NULL,
    [ReferenceType]  NVARCHAR (50)  NULL,
    [ReferenceId]    INT            NULL,
    [Status]         INT            DEFAULT ((1)) NOT NULL,
    [ErrorMessage]   NVARCHAR (MAX) NULL,
    [RetryCount]     INT            DEFAULT ((0)) NOT NULL,
    [CreatedDate]    DATETIME2 (7)  DEFAULT (getutcdate()) NOT NULL,
    [ProcessedDate]  DATETIME2 (7)  NULL,
    [ScheduledDate]  DATETIME2 (7)  NULL,
    PRIMARY KEY CLUSTERED ([LogId] ASC)
);


GO
CREATE NONCLUSTERED INDEX [IX_CommunicationLogs_Status]
    ON [assoc].[CommunicationLogs]([Status] ASC);


GO
CREATE NONCLUSTERED INDEX [IX_CommunicationLogs_Tenant_Assoc]
    ON [assoc].[CommunicationLogs]([TenantId] ASC, [AssociationId] ASC);

