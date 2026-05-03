-- 3. Redeploy procedures with snapshot/priority logic
-- (Invoices procs, Dashboard, Balances, Summary)

-- sp_Invoices_Create
CREATE   PROCEDURE assoc.sp_Invoices_Create 
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
    SET NOCOUNT ON;
    DECLARE @FineStrategy NVARCHAR(50), @FineValue DECIMAL(18,2), @FineGracePeriod INT, @FineIsCompounding BIT;
    SELECT @FineStrategy = StrategyType, @FineValue = FineValue, @FineGracePeriod = GracePeriodDays, @FineIsCompounding = IsCompounding
    FROM assoc.FineSettings WHERE AssociationId = @AssociationId AND TenantId = @TenantId;
    INSERT INTO assoc.Invoices (TenantId, AssociationId, AssetId, BillingBatchId, Title, Description, Amount, DueDate, Status, CreatedDate, FineStrategy, FineValue, FineGracePeriod, FineIsCompounding) 
    VALUES (@TenantId, @AssociationId, @AssetId, @BillingBatchId, @Title, @Description, @Amount, @DueDate, @Status, @CreatedDate, @FineStrategy, @FineValue, @FineGracePeriod, @FineIsCompounding); 
    SELECT SCOPE_IDENTITY(); 
END
GO