CREATE TABLE [assoc].[Transactions] (
    [TransactionId]   BIGINT          IDENTITY (1, 1) NOT NULL,
    [TenantId]        INT             NOT NULL,
    [AssetId]         INT             NOT NULL,
    [InvoiceId]       INT             NULL,
    [PaymentId]       INT             NULL,
    [Type]            NVARCHAR (10)   NOT NULL,
    [Amount]          DECIMAL (18, 2) NOT NULL,
    [Category]        NVARCHAR (100)  NOT NULL,
    [Description]     NVARCHAR (500)  NULL,
    [TransactionDate] DATETIME        DEFAULT (getdate()) NOT NULL,
    [AssociationId]   INT             NOT NULL,
    PRIMARY KEY CLUSTERED ([TransactionId] ASC),
    CONSTRAINT [FK_Transactions_Assets] FOREIGN KEY ([AssetId]) REFERENCES [assoc].[Assets] ([AssetId]),
    CONSTRAINT [FK_Transactions_Associations] FOREIGN KEY ([AssociationId]) REFERENCES [corp].[Associations] ([AssociationId]),
    CONSTRAINT [FK_Transactions_Tenants] FOREIGN KEY ([TenantId]) REFERENCES [corp].[Tenants] ([TenantId])
);


GO
CREATE NONCLUSTERED INDEX [IX_Transactions_AssociationId]
    ON [assoc].[Transactions]([AssociationId] ASC);

