-- 2. Create Summary Stats Procedure for Dashboard Header
CREATE   PROCEDURE assoc.sp_Finance_GetSummaryStats
    @TenantId INT,
    @AssociationId INT = NULL,
    @AssetId INT = NULL
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @TotalUnpaid DECIMAL(18,2) = 0;
    DECLARE @Collected30Days DECIMAL(18,2) = 0;

    -- Total Unpaid Invoices
    SELECT @TotalUnpaid = SUM(Amount)
    FROM assoc.Invoices
    WHERE TenantId = @TenantId
    AND (@AssociationId IS NULL OR AssociationId = @AssociationId)
    AND (@AssetId IS NULL OR AssetId = @AssetId)
    AND Status = 'Unpaid';

    -- Collected in last 30 days
    SELECT @Collected30Days = SUM(Amount)
    FROM assoc.Payments
    WHERE TenantId = @TenantId
    AND (@AssociationId IS NULL OR AssociationId = @AssociationId)
    AND (@AssetId IS NULL OR AssetId = @AssetId)
    AND Status = 'Paid'
    AND CreatedDate >= DATEADD(DAY, -30, GETDATE());

    SELECT 
        ISNULL(@TotalUnpaid, 0) as TotalUnpaid,
        ISNULL(@Collected30Days, 0) as Collected30Days;
END;