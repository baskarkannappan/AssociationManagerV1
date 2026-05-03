CREATE PROCEDURE assoc.sp_Dashboard_GetTotalMembers
    @TenantId INT,
    @AssociationId INT
AS
BEGIN
    SET NOCOUNT ON;
    SELECT COUNT(DISTINCT PersonId) 
    FROM assoc.Occupancy 
    WHERE TenantId = @TenantId AND AssociationId = @AssociationId;
END