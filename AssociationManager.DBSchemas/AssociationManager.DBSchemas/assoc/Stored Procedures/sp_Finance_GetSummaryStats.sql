
-- 1. Update Summary Stats with robust status and trimming
CREATE   PROCEDURE assoc.sp_Finance_GetSummaryStats
    @TenantId INT,
    @AssociationId INT = NULL,
    @AssetId INT = NULL,
    @AssetIds NVARCHAR(MAX) = NULL 
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @TotalUnpaid DECIMAL(18,2) = 0;
    DECLARE @Collected30Days DECIMAL(18,2) = 0;

    -- Total Unpaid Invoices (using TRIM and case-insensitive check)
    SELECT @TotalUnpaid = SUM(Amount)
    FROM assoc.Invoices
    WHERE TenantId = @TenantId
    AND (@AssociationId IS NULL OR AssociationId = @AssociationId)
    AND (@AssetId IS NULL OR AssetId = @AssetId)
    AND (@AssetIds IS NULL OR AssetId IN (SELECT CAST(value AS INT) FROM STRING_SPLIT(@AssetIds, ',')))
    AND LTRIM(RTRIM(Status)) IN ('Unpaid', 'unpaid', 'Partial', 'partial');

    -- Collected in last 30 days
    -- Includes captured gateway payments and manual payments, excludes internal auto-settlements
    SELECT @Collected30Days = SUM(Amount)
    FROM assoc.Payments
    WHERE TenantId = @TenantId
    AND (@AssociationId IS NULL OR AssociationId = @AssociationId)
    AND (@AssetId IS NULL OR AssetId = @AssetId)
    AND (@AssetIds IS NULL OR AssetId IN (SELECT CAST(value AS INT) FROM STRING_SPLIT(@AssetIds, ',')))
    AND LTRIM(RTRIM(Status)) IN ('Paid', 'paid', 'Captured', 'captured', 'Completed', 'completed')
    AND (Notes IS NULL OR Notes NOT LIKE 'Auto-Settled%')
    AND CreatedDate >= DATEADD(DAY, -30, GETDATE());

    SELECT 
        CAST(ISNULL(@TotalUnpaid, 0) AS DECIMAL(18,2)) as TotalUnpaid,
        CAST(ISNULL(@Collected30Days, 0) AS DECIMAL(18,2)) as Collected30Days;
END;