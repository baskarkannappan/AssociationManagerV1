-- sp_Finance_GetSummaryStats
CREATE   PROCEDURE assoc.sp_Finance_GetSummaryStats
    @TenantId INT, 
    @AssociationId INT, 
    @AssetId INT = NULL, 
    @AssetIds NVARCHAR(MAX) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    
    DECLARE @TotalUnpaid DECIMAL(18,2) = 0, @Collected30Days DECIMAL(18,2) = 0;

    -- 1. Calculate Unpaid Balance from Snapshot
    SELECT @TotalUnpaid = ISNULL(SUM(OutstandingAmount - PaidAmount), 0)
    FROM assoc.AssetBalancesSnapshot
    WHERE TenantId = @TenantId 
      AND AssociationId = @AssociationId
      AND (@AssetId IS NULL OR AssetId = @AssetId)
      AND (@AssetIds IS NULL OR AssetId IN (SELECT CAST(value AS INT) FROM STRING_SPLIT(@AssetIds, ',')))
      AND OutstandingAmount > PaidAmount;

    -- 2. Calculate 30-Day Collections (Direct from Payments)
    SELECT @Collected30Days = SUM(Amount) 
    FROM assoc.Payments WITH (NOLOCK) 
    WHERE TenantId = @TenantId 
      AND AssociationId = @AssociationId 
      AND (@AssetId IS NULL OR AssetId = @AssetId) 
      AND (@AssetIds IS NULL OR AssetId IN (SELECT CAST(value AS INT) FROM STRING_SPLIT(@AssetIds, ','))) 
      AND Status IN ('Paid', 'Captured', 'Completed') 
      AND (Notes IS NULL OR Notes NOT LIKE 'Auto-Settled%') 
      AND CreatedDate >= DATEADD(DAY, -30, GETDATE());

    SELECT 
        CAST(ISNULL(@TotalUnpaid, 0) AS DECIMAL(18,2)) as TotalUnpaid, 
        CAST(ISNULL(@Collected30Days, 0) AS DECIMAL(18,2)) as Collected30Days;
END