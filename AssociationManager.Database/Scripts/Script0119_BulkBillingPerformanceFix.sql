-- Script 0060: Bulk Billing Optimization
-- Includes Table-Valued Parameters and Bulk Stored Procedures

-- 1. Create User-Defined Table Types
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
        [TempId]         NVARCHAR(100)
    );
END
GO

IF NOT EXISTS (SELECT * FROM sys.types WHERE name = 'typ_InvoiceLineItemBatch' AND schema_id = SCHEMA_ID('assoc'))
BEGIN
    CREATE TYPE [assoc].[typ_InvoiceLineItemBatch] AS TABLE (
        [TempInvoiceId]  NVARCHAR(100),
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

-- 2. Stored Procedure for Bulk Invoices
CREATE OR ALTER PROCEDURE [assoc].[sp_Invoices_CreateBulk]
    @TenantId INT,
    @AssociationId INT,
    @Invoices [assoc].[typ_InvoiceBatch] READONLY,
    @LineItems [assoc].[typ_InvoiceLineItemBatch] READONLY
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    BEGIN TRANSACTION;

    DECLARE @IdMapping TABLE (InvoiceId INT, TempId NVARCHAR(100));

    MERGE INTO [assoc].[Invoices] AS Target
    USING @Invoices AS Source
    ON 1 = 0
    WHEN NOT MATCHED THEN
        INSERT (TenantId, AssociationId, AssetId, BillingBatchId, Title, Description, Amount, DueDate, Status, CreatedDate)
        VALUES (@TenantId, @AssociationId, Source.AssetId, Source.BillingBatchId, Source.Title, Source.Description, Source.Amount, Source.DueDate, Source.Status, Source.CreatedDate)
    OUTPUT inserted.InvoiceId, Source.TempId INTO @IdMapping(InvoiceId, TempId);

    INSERT INTO [assoc].[InvoiceLineItems] (InvoiceId, ChargeName, Amount, Description, TariffLayerId, Rate)
    SELECT m.InvoiceId, li.ChargeName, li.Amount, li.Description, li.TariffLayerId, li.Rate
    FROM @LineItems li
    INNER JOIN @IdMapping m ON li.TempInvoiceId = m.TempId;

    COMMIT TRANSACTION;

    SELECT InvoiceId, TempId FROM @IdMapping;
END
GO

-- 3. Stored Procedure for Bulk Audit Logs
CREATE OR ALTER PROCEDURE [assoc].[sp_AuditLogs_CreateBulk]
    @TenantId INT,
    @AssociationId INT,
    @UserId INT,
    @Logs [assoc].[typ_AuditLogBatch] READONLY
AS
BEGIN
    SET NOCOUNT ON;

    INSERT INTO [assoc].[AuditLogs] (TenantId, AssociationId, UserId, AssetId, Action, Entity, EntityId, Timestamp)
    SELECT @TenantId, @AssociationId, @UserId, AssetId, Action, Entity, EntityId, Timestamp
    FROM @Logs;
END
GO

-- 4. Stored Procedure for Idempotent Batch Check
CREATE OR ALTER PROCEDURE [assoc].[sp_BillingBatches_GetDraft]
    @AssociationId INT,
    @Month INT,
    @Year INT,
    @TenantId INT
AS
BEGIN
    SELECT TOP 1 *
    FROM [assoc].[BillingBatches]
    WHERE AssociationId = @AssociationId 
      AND Month = @Month 
      AND Year = @Year 
      AND Status = 'Draft'
      AND TenantId = @TenantId
    ORDER BY BillingBatchId DESC;
END
GO
