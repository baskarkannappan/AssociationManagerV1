CREATE TABLE [assoc].[PaymentTransactions] (
    [Id]                   INT             IDENTITY (1, 1) NOT NULL,
    [TenantId]             INT             NOT NULL,
    [AssociationId]        INT             NOT NULL,
    [PaymentOrderId]       INT             NULL,
    [RazorpayPaymentId]    NVARCHAR (255)  NOT NULL,
    [RazorpayOrderId]      NVARCHAR (255)  NOT NULL,
    [RazorpaySignature]    NVARCHAR (MAX)  NOT NULL,
    [Status]               NVARCHAR (50)   NOT NULL,
    [Amount]               DECIMAL (18, 2) NOT NULL,
    [RawResponse]          NVARCHAR (MAX)  NULL,
    [CreatedDate]          DATETIME        DEFAULT (getutcdate()) NOT NULL,
    [PrimaryAccountName]   NVARCHAR (200)  NULL,
    [PrimaryAccountNumber] NVARCHAR (100)  NULL,
    [PaymentMethod]        NVARCHAR (50)   NULL,
    [BankName]             NVARCHAR (100)  NULL,
    [BankRrn]              NVARCHAR (100)  NULL,
    [CardNetwork]          NVARCHAR (50)   NULL,
    [GatewayFee]           DECIMAL (18, 2) NULL,
    [GatewayTax]           DECIMAL (18, 2) NULL,
    PRIMARY KEY CLUSTERED ([Id] ASC),
    CONSTRAINT [FK_PaymentTransactions_Order] FOREIGN KEY ([PaymentOrderId]) REFERENCES [assoc].[PaymentOrders] ([Id]),
    UNIQUE NONCLUSTERED ([RazorpayPaymentId] ASC)
);


GO
CREATE NONCLUSTERED INDEX [IX_PaymentTransactions_RazorpayOrderId]
    ON [assoc].[PaymentTransactions]([RazorpayOrderId] ASC);


GO
CREATE NONCLUSTERED INDEX [IX_PaymentTransactions_RazorpayPaymentId]
    ON [assoc].[PaymentTransactions]([RazorpayPaymentId] ASC);

