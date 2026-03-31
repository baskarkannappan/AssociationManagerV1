CREATE TABLE [corp].[TenantPaymentConfig] (
    [Id]                    INT            IDENTITY (1, 1) NOT NULL,
    [TenantId]              INT            NOT NULL,
    [RazorpayKeyId]         NVARCHAR (255) NOT NULL,
    [RazorpayKeySecret]     NVARCHAR (255) NOT NULL,
    [WebhookSecret]         NVARCHAR (255) NULL,
    [IsActive]              BIT            DEFAULT ((1)) NOT NULL,
    [LastUpdated]           DATETIME       DEFAULT (getutcdate()) NOT NULL,
    [RazorpayWebhookSecret] NVARCHAR (255) NULL,
    PRIMARY KEY CLUSTERED ([Id] ASC),
    CONSTRAINT [FK_TenantPaymentConfig_Tenant] FOREIGN KEY ([TenantId]) REFERENCES [corp].[Tenants] ([TenantId]),
    UNIQUE NONCLUSTERED ([TenantId] ASC)
);

