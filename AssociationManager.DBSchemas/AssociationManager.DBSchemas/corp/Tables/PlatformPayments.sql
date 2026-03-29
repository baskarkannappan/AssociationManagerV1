CREATE TABLE [corp].[PlatformPayments] (
    [PlatformPaymentId] INT             IDENTITY (1, 1) NOT NULL,
    [PlatformInvoiceId] INT             NOT NULL,
    [Amount]            DECIMAL (18, 2) NOT NULL,
    [PaymentDate]       DATETIME        DEFAULT (getutcdate()) NOT NULL,
    [TransactionRef]    NVARCHAR (255)  NULL,
    PRIMARY KEY CLUSTERED ([PlatformPaymentId] ASC),
    CONSTRAINT [FK_PlatformPayments_Invoice] FOREIGN KEY ([PlatformInvoiceId]) REFERENCES [corp].[PlatformInvoices] ([PlatformInvoiceId])
);

