
-- 5. Asset Count (Move to SP)
CREATE   PROCEDURE assoc.sp_Assets_Count
    @TenantId INT,
    @AssociationId INT
AS
BEGIN
    SELECT COUNT(*) FROM assoc.Assets 
    WHERE TenantId = @TenantId 
    AND AssociationId = @AssociationId 
    AND IsActive = 1;
END;