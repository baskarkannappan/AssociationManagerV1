-- TARIFF GROUPS
CREATE   PROCEDURE assoc.sp_TariffGroups_GetByTenantId @TenantId INT, @AssociationId INT = NULL AS 
BEGIN SELECT * FROM assoc.TariffGroups WHERE TenantId = @TenantId AND (AssociationId = @AssociationId OR (@AssociationId IS NULL AND AssociationId IS NULL)); END