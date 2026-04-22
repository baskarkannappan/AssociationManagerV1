-- sp_Invoices_CreateBulk
CREATE   PROCEDURE [assoc].[sp_Invoices_CreateBulk]
    @TenantId INT, @AssociationId INT, @Invoices [assoc].[typ_InvoiceBatch] READONLY, @LineItems [assoc].[typ_InvoiceLineItemBatch] READONLY
AS
BEGIN
    SET NOCOUNT ON; SET XACT_ABORT ON;
    BEGIN TRANSACTION;
    DECLARE @IdMapping TABLE (InvoiceId INT, TempId NVARCHAR(100));
    MERGE INTO [assoc].[Invoices] AS Target
    USING (SELECT s.*, fs.StrategyType, fs.FineValue, fs.GracePeriodDays, fs.IsCompounding FROM @Invoices s OUTER APPLY (SELECT TOP 1 StrategyType, FineValue, GracePeriodDays, IsCompounding FROM assoc.FineSettings WHERE AssociationId = @AssociationId AND TenantId = @TenantId) fs) AS Source
    ON 1 = 0 WHEN NOT MATCHED THEN
        INSERT (TenantId, AssociationId, AssetId, BillingBatchId, Title, Description, Amount, DueDate, Status, CreatedDate, FineStrategy, FineValue, FineGracePeriod, FineIsCompounding)
        VALUES (@TenantId, @AssociationId, Source.AssetId, Source.BillingBatchId, Source.Title, Source.Description, Source.Amount, Source.DueDate, Source.Status, Source.CreatedDate, Source.StrategyType, Source.FineValue, Source.GracePeriodDays, Source.IsCompounding)
    OUTPUT inserted.InvoiceId, Source.TempId INTO @IdMapping(InvoiceId, TempId);
    INSERT INTO [assoc].[InvoiceLineItems] (InvoiceId, ChargeName, Amount, Description, TariffLayerId, Rate)
    SELECT m.InvoiceId, li.ChargeName, li.Amount, li.Description, li.TariffLayerId, li.Rate FROM @LineItems li INNER JOIN @IdMapping m ON li.TempInvoiceId = m.TempId;
    COMMIT TRANSACTION;
    SELECT InvoiceId, TempId FROM @IdMapping;
END