-- User Defined Table Types for Bulk Operations
IF NOT EXISTS (SELECT * FROM sys.types WHERE name = 'typ_InvoiceBatch' AND schema_id = SCHEMA_ID('assoc'))
BEGIN
    CREATE TYPE [assoc].[typ_InvoiceBatch] AS TABLE (
        [AssetId]        INT,
        [Title]          NVARCHAR (200),
        [Description]    NVARCHAR (500),
        [Amount]         DECIMAL (18, 2),
        [DueDate]        DATETIME,
        [Status]         NVARCHAR (50),
        [CreatedDate]    DATETIME,
        [BillingBatchId] INT,
        [TempId]         NVARCHAR(100) -- Used to link Line Items before InvoiceId is generated
    );
END
GO

IF NOT EXISTS (SELECT * FROM sys.types WHERE name = 'typ_InvoiceLineItemBatch' AND schema_id = SCHEMA_ID('assoc'))
BEGIN
    CREATE TYPE [assoc].[typ_InvoiceLineItemBatch] AS TABLE (
        [TempInvoiceId]  NVARCHAR(100), -- Matches TempId in typ_InvoiceBatch
        [ChargeName]     NVARCHAR (200),
        [Amount]         DECIMAL (18, 2),
        [Description]    NVARCHAR (MAX),
        [TariffLayerId]  INT,
        [Rate]           DECIMAL (18, 2)
    );
END
GO

IF NOT EXISTS (SELECT * FROM sys.types WHERE name = 'typ_AuditLogBatch' AND schema_id = SCHEMA_ID('assoc'))
BEGIN
    CREATE TYPE [assoc].[typ_AuditLogBatch] AS TABLE (
        [AssetId]        INT,
        [Action]         NVARCHAR (MAX),
        [Entity]         NVARCHAR (100),
        [EntityId]       INT,
        [Timestamp]      DATETIME
    );
END
GO
