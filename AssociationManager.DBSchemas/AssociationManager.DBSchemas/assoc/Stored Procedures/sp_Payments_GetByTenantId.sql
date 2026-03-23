CREATE   PROCEDURE assoc.sp_Payments_GetByTenantId @TenantId INT, @AssociationId INT AS 
BEGIN SELECT * FROM assoc.Payments WHERE TenantId = @TenantId AND AssociationId = @AssociationId; END