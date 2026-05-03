-- 5. Fix Revenue 30D
CREATE   PROCEDURE assoc.sp_Dashboard_GetRevenue30D
    @TenantId INT,
    @AssociationId INT,
    @Revenue_OUT DECIMAL(18,2) = NULL OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @TotalCash DECIMAL(18,2) = 0;
    SELECT @TotalCash = ISNULL(SUM(Amount), 0) FROM assoc.Payments WHERE TenantId = @TenantId AND AssociationId = @AssociationId AND Status IN ('Paid', 'Completed', 'Captured') AND CreatedDate >= DATEADD(DAY, -30, GETDATE());
    IF @Revenue_OUT IS NOT NULL SET @Revenue_OUT = @TotalCash;
    SET @Revenue_OUT = @TotalCash;
    SELECT CAST(@TotalCash AS DECIMAL(18,2)) as Revenue;
END