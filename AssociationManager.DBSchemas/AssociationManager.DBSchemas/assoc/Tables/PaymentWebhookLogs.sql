CREATE TABLE [assoc].[PaymentWebhookLogs] (
    [Id]          INT            IDENTITY (1, 1) NOT NULL,
    [TenantId]    INT            NULL,
    [EventType]   NVARCHAR (255) NOT NULL,
    [RawPayload]  NVARCHAR (MAX) NOT NULL,
    [Signature]   NVARCHAR (MAX) NULL,
    [IsProcessed] BIT            DEFAULT ((0)) NOT NULL,
    [CreatedDate] DATETIME       DEFAULT (getutcdate()) NOT NULL,
    PRIMARY KEY CLUSTERED ([Id] ASC)
);

