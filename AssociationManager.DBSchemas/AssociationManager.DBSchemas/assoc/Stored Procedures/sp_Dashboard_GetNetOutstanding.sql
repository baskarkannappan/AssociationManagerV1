-- 2. Fix Net Outstanding Dashboard Proc
CREATE PROCEDURE assoc.sp_Dashboard_GetNetOutstanding
    @TenantId INT, @AssociationId INT
AS
BEGIN
    SET NOCOUNT ON;
    SELECT CAST(ISNULL(SUM(OutstandingAmount - PaidAmount), 0) AS DECIMAL(18,2)) 
    FROM assoc.AssetBalancesSnapshot 
    WHERE TenantId = @TenantId AND AssociationId = @AssociationId AND OutstandingAmount > PaidAmount;
END