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

GO
CREATE NONCLUSTERED INDEX [IX_Transactions_WalletSearch]
    ON [assoc].[Transactions]([AssociationId] ASC, [TenantId] ASC, [AssetId] ASC)
    INCLUDE ([Type], [Category], [Amount]);



GO
CREATE NONCLUSTERED INDEX [IX_Transactions_InvoiceId]
    ON [assoc].[Transactions]([InvoiceId] ASC);


GO
CREATE   TRIGGER assoc.tr_Transactions_SyncDashboard ON assoc.Transactions AFTER INSERT, UPDATE, DELETE AS BEGIN SET NOCOUNT ON; DECLARE @Aid INT; SELECT TOP 1 @Aid = AssociationId FROM (SELECT AssociationId FROM inserted UNION SELECT AssociationId FROM deleted) x; IF @Aid IS NOT NULL EXEC assoc.sp_AssociationBalances_Sync @AssociationId = @Aid; END;