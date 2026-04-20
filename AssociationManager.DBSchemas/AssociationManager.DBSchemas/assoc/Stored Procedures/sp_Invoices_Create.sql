CREATE PROCEDURE assoc.sp_Invoices_Create 
    @TenantId INT, 
    @AssociationId INT, 
    @AssetId INT = NULL, 
    @BillingBatchId INT = NULL, 
    @Title NVARCHAR(200), 
    @Description NVARCHAR(MAX) = NULL, 
    @Amount DECIMAL(18, 2), 
    @DueDate DATETIME, 
    @Status NVARCHAR(50), 
    @CreatedDate DATETIME 
AS 
BEGIN 
    INSERT INTO assoc.Invoices (TenantId, AssociationId, AssetId, BillingBatchId, Title, Description, Amount, DueDate, Status, CreatedDate) 
    VALUES (@TenantId, @AssociationId, @AssetId, @BillingBatchId, @Title, @Description, @Amount, @DueDate, @Status, @CreatedDate); 
    SELECT SCOPE_IDENTITY(); 
END