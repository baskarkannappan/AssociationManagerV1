CREATE TABLE [assoc].[BillingBatches] (
    [BillingBatchId]    INT             IDENTITY (1, 1) NOT NULL,
    [TenantId]          INT             NOT NULL,
    [AssociationId]     INT             NOT NULL,
    [Month]             INT             NOT NULL,
    [Year]              INT             NOT NULL,
    [Status]            NVARCHAR (50)   DEFAULT ('Committed') NOT NULL,
    [TotalAmount]       DECIMAL (18, 2) DEFAULT ((0)) NOT NULL,
    [InvoicesGenerated] INT             DEFAULT ((0)) NOT NULL,
    [CreatedDate]       DATETIME        DEFAULT (getdate()) NOT NULL,
    PRIMARY KEY CLUSTERED ([BillingBatchId] ASC),
    CONSTRAINT [FK_BillingBatches_Associations] FOREIGN KEY ([AssociationId]) REFERENCES [corp].[Associations] ([AssociationId]),
    CONSTRAINT [FK_BillingBatches_Tenants] FOREIGN KEY ([TenantId]) REFERENCES [corp].[Tenants] ([TenantId])
);

