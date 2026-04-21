CREATE TABLE [assoc].[Payments] (
    [PaymentId]        INT             IDENTITY (1, 1) NOT NULL,
    [TenantId]         INT             NOT NULL,
    [UserId]           INT             NOT NULL,
    [Amount]           DECIMAL (18, 2) NOT NULL,
    [Currency]         NVARCHAR (10)   NOT NULL,
    [Status]           NVARCHAR (50)   NOT NULL,
    [CreatedDate]      DATETIME        DEFAULT (getdate()) NOT NULL,
    [GatewayReference] NVARCHAR (200)  NULL,
    [InvoiceId]        INT             NULL,
    [AssetId]          INT             NULL,
    [Notes]            NVARCHAR (500)  NULL,
    [AssociationId]    INT             NOT NULL,
    PRIMARY KEY CLUSTERED ([PaymentId] ASC),
    CONSTRAINT [FK_Payments_Assets] FOREIGN KEY ([AssetId]) REFERENCES [assoc].[Assets] ([AssetId]),
    CONSTRAINT [FK_Payments_Associations] FOREIGN KEY ([AssociationId]) REFERENCES [corp].[Associations] ([AssociationId]),
    CONSTRAINT [FK_Payments_Invoices] FOREIGN KEY ([InvoiceId]) REFERENCES [assoc].[Invoices] ([InvoiceId]),
    CONSTRAINT [FK_Payments_Tenants] FOREIGN KEY ([TenantId]) REFERENCES [corp].[Tenants] ([TenantId])
);


GO
CREATE NONCLUSTERED INDEX [IX_Payments_AssociationId]
    ON [assoc].[Payments]([AssociationId] ASC);

GO
CREATE NONCLUSTERED INDEX [IX_Payments_TenantId]
    ON [assoc].[Payments]([TenantId] ASC);

GO
CREATE NONCLUSTERED INDEX [IX_Payments_Status]
    ON [assoc].[Payments]([Status] ASC);

GO
CREATE NONCLUSTERED INDEX [IX_Payments_AssetId]
    ON [assoc].[Payments]([AssetId] ASC);

GO
CREATE NONCLUSTERED INDEX [IX_Payments_Association_Status_Date]
    ON [assoc].[Payments]([AssociationId] ASC, [Status] ASC, [CreatedDate] ASC)
    INCLUDE ([Amount]);


