CREATE TABLE [assoc].[InvoiceLineItems] (
    [InvoiceLineItemId] INT             IDENTITY (1, 1) NOT NULL,
    [InvoiceId]         INT             NOT NULL,
    [ChargeName]        NVARCHAR (200)  NOT NULL,
    [Amount]            DECIMAL (18, 2) NOT NULL,
    [Description]       NVARCHAR (MAX)  NULL,
    [TariffLayerId]     INT             NULL,
    [Rate]              DECIMAL (18, 2) NULL,
    PRIMARY KEY CLUSTERED ([InvoiceLineItemId] ASC),
    CONSTRAINT [FK_InvoiceLineItems_Invoices] FOREIGN KEY ([InvoiceId]) REFERENCES [assoc].[Invoices] ([InvoiceId]) ON DELETE CASCADE
);

GO
CREATE NONCLUSTERED INDEX [IX_InvoiceLineItems_InvoiceId]
    ON [assoc].[InvoiceLineItems]([InvoiceId] ASC)
    INCLUDE ([Amount], [ChargeName]);

