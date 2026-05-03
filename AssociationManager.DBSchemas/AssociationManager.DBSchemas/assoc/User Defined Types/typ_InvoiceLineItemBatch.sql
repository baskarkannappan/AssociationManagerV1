CREATE TYPE [assoc].[typ_InvoiceLineItemBatch] AS TABLE (
    [TempInvoiceId] NVARCHAR (100)  NULL,
    [ChargeName]    NVARCHAR (200)  NULL,
    [Amount]        DECIMAL (18, 2) NULL,
    [Description]   NVARCHAR (MAX)  NULL,
    [TariffLayerId] INT             NULL,
    [Rate]          DECIMAL (18, 2) NULL);

