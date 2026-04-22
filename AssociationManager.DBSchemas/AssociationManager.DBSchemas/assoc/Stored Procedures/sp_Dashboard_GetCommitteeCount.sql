-- 4. Fix Committee Count
CREATE   PROCEDURE assoc.sp_Dashboard_GetCommitteeCount
    @TenantId INT,
    @AssociationId INT
AS
BEGIN
    SET NOCOUNT ON;
    SELECT COUNT(*) 
    FROM assoc.CommitteeMembers 
    WHERE AssociationId = @AssociationId AND IsActive = 1;
END