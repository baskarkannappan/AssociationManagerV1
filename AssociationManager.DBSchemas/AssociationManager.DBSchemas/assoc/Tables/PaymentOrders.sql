CREATE TABLE [assoc].[PaymentOrders] (
    [Id]                   INT             IDENTITY (1, 1) NOT NULL,
    [TenantId]             INT             NOT NULL,
    [AssociationId]        INT             NOT NULL,
    [UserId]               INT             NOT NULL,
    [RazorpayOrderId]      NVARCHAR (255)  NOT NULL,
    [Amount]               DECIMAL (18, 2) NOT NULL,
    [Currency]             NVARCHAR (10)   DEFAULT ('INR') NOT NULL,
    [Status]               NVARCHAR (50)   DEFAULT ('Created') NOT NULL,
    [InvoiceId]            INT             NULL,
    [Receipt]              NVARCHAR (255)  NULL,
    [CreatedDate]          DATETIME        DEFAULT (getutcdate()) NOT NULL,
    [PrimaryAccountName]   NVARCHAR (200)  NULL,
    [PrimaryAccountNumber] NVARCHAR (100)  NULL,
    [AssetId]              INT             NULL,
    PRIMARY KEY CLUSTERED ([Id] ASC),
    CONSTRAINT [FK_PaymentOrders_Assets] FOREIGN KEY ([AssetId]) REFERENCES [assoc].[Assets] ([AssetId]),
    CONSTRAINT [FK_PaymentOrders_Invoice] FOREIGN KEY ([InvoiceId]) REFERENCES [assoc].[Invoices] ([InvoiceId]),
    UNIQUE NONCLUSTERED ([RazorpayOrderId] ASC)
);




GO
CREATE NONCLUSTERED INDEX [IX_PaymentOrders_TenantAssoc]
    ON [assoc].[PaymentOrders]([TenantId] ASC, [AssociationId] ASC);


GO
CREATE NONCLUSTERED INDEX [IX_PaymentOrders_RazorpayOrderId]
    ON [assoc].[PaymentOrders]([RazorpayOrderId] ASC);

