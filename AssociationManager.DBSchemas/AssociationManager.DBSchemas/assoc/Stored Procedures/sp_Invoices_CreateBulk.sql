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

    -- 1. Create a mapping table to hold InvoiceIds and TempIds
    DECLARE @IdMapping TABLE (InvoiceId INT, TempId NVARCHAR(100));

    -- 2. Insert Invoices and capture generated IDs
    -- We use MERGE to output both generated ID and TempId
    -- (INSERT...OUTPUT only allows columns from the inserted table)
    MERGE INTO [assoc].[Invoices] AS Target
    USING @Invoices AS Source
    ON 1 = 0 -- Always mismatch to force insert
    WHEN NOT MATCHED THEN
        INSERT (TenantId, AssociationId, AssetId, BillingBatchId, Title, Description, Amount, DueDate, Status, CreatedDate)
        VALUES (@TenantId, @AssociationId, Source.AssetId, Source.BillingBatchId, Source.Title, Source.Description, Source.Amount, Source.DueDate, Source.Status, Source.CreatedDate)
    OUTPUT inserted.InvoiceId, Source.TempId INTO @IdMapping(InvoiceId, TempId);

    -- 3. Insert Line Items using the mapping
    INSERT INTO [assoc].[InvoiceLineItems] (InvoiceId, ChargeName, Amount, Description, TariffLayerId, Rate)
    SELECT m.InvoiceId, li.ChargeName, li.Amount, li.Description, li.TariffLayerId, li.Rate
    FROM @LineItems li
    INNER JOIN @IdMapping m ON li.TempInvoiceId = m.TempId;

    COMMIT TRANSACTION;

    -- Return the mapping for any further C# logic if needed (e.g. audit logging)
    SELECT InvoiceId, TempId FROM @IdMapping;
END
GO
