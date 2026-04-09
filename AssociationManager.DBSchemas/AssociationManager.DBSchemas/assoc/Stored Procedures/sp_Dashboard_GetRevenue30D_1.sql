
CREATE PROCEDURE assoc.sp_Dashboard_GetRevenue30D
    @TenantId INT,
    @AssociationId INT
AS
BEGIN
    SET NOCOUNT ON;
    SELECT ISNULL(SUM(Amount), 0) 
    FROM assoc.Payments 
    WHERE TenantId = @TenantId 
    AND AssociationId = @AssociationId 
    AND Status IN ('Paid', 'Completed', 'Captured')
    AND CreatedDate >= DATEADD(DAY, -30, GETDATE())
    AND (
        (Notes IS NULL) OR 
        (Notes NOT LIKE '%Settled%' AND Notes NOT LIKE '%Deduction%' AND Notes NOT LIKE '%Adjustment%')
    );
END