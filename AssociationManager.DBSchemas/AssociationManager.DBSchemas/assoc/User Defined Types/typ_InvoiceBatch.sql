CREATE TYPE [assoc].[typ_InvoiceBatch] AS TABLE (
    [AssetId]        INT             NULL,
    [Title]          NVARCHAR (200)  NULL,
    [Description]    NVARCHAR (500)  NULL,
    [Amount]         DECIMAL (18, 2) NULL,
    [DueDate]        DATETIME        NULL,
    [Status]         NVARCHAR (50)   NULL,
    [CreatedDate]    DATETIME        NULL,
    [BillingBatchId] INT             NULL,
    [TempId]         NVARCHAR (100)  NULL);

