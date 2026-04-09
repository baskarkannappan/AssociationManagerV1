CREATE PROCEDURE assoc.sp_Invoices_Update
    @Id INT,
    @TenantId INT,
    @AssociationId INT,
    @AssetId INT = NULL,
    @BillingBatchId INT = NULL,
    @Title NVARCHAR(200),
    @Description NVARCHAR(500),
    @Amount DECIMAL(18, 2),
    @DueDate DATETIME,
    @Status NVARCHAR(50)
AS
BEGIN
    SET NOCOUNT ON;
    UPDATE assoc.Invoices
    SET 
        AssetId = @AssetId,
        BillingBatchId = @BillingBatchId,
        Title = @Title,
        [Description] = @Description,
        Amount = @Amount,
        DueDate = @DueDate,
        [Status] = @Status
    WHERE InvoiceId = @Id
    AND TenantId = @TenantId
    AND AssociationId = @AssociationId;
END
GO
