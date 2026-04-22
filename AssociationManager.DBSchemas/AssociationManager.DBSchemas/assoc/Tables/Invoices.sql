CREATE TABLE [assoc].[Invoices] (
    [InvoiceId]         INT             IDENTITY (1, 1) NOT NULL,
    [TenantId]          INT             NOT NULL,
    [AssetId]           INT             NULL,
    [Title]             NVARCHAR (200)  NOT NULL,
    [Description]       NVARCHAR (500)  NULL,
    [Amount]            DECIMAL (18, 2) NOT NULL,
    [DueDate]           DATETIME        NOT NULL,
    [Status]            NVARCHAR (50)   DEFAULT ('Unpaid') NOT NULL,
    [CreatedDate]       DATETIME        DEFAULT (getdate()) NOT NULL,
    [AssociationId]     INT             NOT NULL,
    [BillingBatchId]    INT             NULL,
    [IsAdvancePaid]     BIT             DEFAULT ((0)) NOT NULL,
    [FineStrategy]      NVARCHAR (50)   NULL,
    [FineValue]         DECIMAL (18, 2) NULL,
    [FineGracePeriod]   INT             NULL,
    [FineIsCompounding] BIT             NULL,
    PRIMARY KEY CLUSTERED ([InvoiceId] ASC),
    CONSTRAINT [FK_Invoices_Assets] FOREIGN KEY ([AssetId]) REFERENCES [assoc].[Assets] ([AssetId]),
    CONSTRAINT [FK_Invoices_Associations] FOREIGN KEY ([AssociationId]) REFERENCES [corp].[Associations] ([AssociationId]),
    CONSTRAINT [FK_Invoices_BillingBatches] FOREIGN KEY ([BillingBatchId]) REFERENCES [assoc].[BillingBatches] ([BillingBatchId]),
    CONSTRAINT [FK_Invoices_Tenants] FOREIGN KEY ([TenantId]) REFERENCES [corp].[Tenants] ([TenantId])
);








GO
CREATE NONCLUSTERED INDEX [IX_Invoices_AssociationId]
    ON [assoc].[Invoices]([AssociationId] ASC);

GO
CREATE NONCLUSTERED INDEX [IX_Invoices_Status] 
    ON [assoc].[Invoices]([Status] ASC);

GO
CREATE NONCLUSTERED INDEX [IX_Invoices_AssetId] 
    ON [assoc].[Invoices]([AssetId] ASC);

GO
CREATE NONCLUSTERED INDEX [IX_Invoices_BillingBatchId] 
    ON [assoc].[Invoices]([BillingBatchId] ASC);

GO
CREATE NONCLUSTERED INDEX [IX_Invoices_TenantId]
    ON [assoc].[Invoices]([TenantId] ASC);

GO
CREATE NONCLUSTERED INDEX [IX_Invoices_AssociationStatus]
    ON [assoc].[Invoices]([AssociationId] ASC, [Status] ASC)
    INCLUDE ([Amount], [DueDate]);



GO
CREATE NONCLUSTERED INDEX [IX_Invoices_Summary]
    ON [assoc].[Invoices]([AssociationId] ASC, [Status] ASC, [TenantId] ASC)
    INCLUDE([Amount], [AssetId]);


GO

CREATE   TRIGGER assoc.tr_Invoices_SyncDashboard ON assoc.Invoices AFTER INSERT, UPDATE, DELETE AS BEGIN SET NOCOUNT ON; DECLARE @Aid INT; SELECT TOP 1 @Aid = AssociationId FROM (SELECT AssociationId FROM inserted UNION SELECT AssociationId FROM deleted) x; IF @Aid IS NOT NULL EXEC assoc.sp_AssociationBalances_Sync @AssociationId = @Aid; END;