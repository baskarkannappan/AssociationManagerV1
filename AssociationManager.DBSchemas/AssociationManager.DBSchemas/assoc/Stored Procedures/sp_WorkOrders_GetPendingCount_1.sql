
-- 3.1 sp_WorkOrders_GetPendingCount
CREATE   PROCEDURE assoc.sp_WorkOrders_GetPendingCount
    @TenantId INT,
    @AssociationId INT
AS
BEGIN
    SET NOCOUNT ON;
    SELECT COUNT(*) 
    FROM assoc.WorkOrders 
    WHERE TenantId = @TenantId AND AssociationId = @AssociationId 
    AND Status NOT IN ('Completed', 'Closed')
END