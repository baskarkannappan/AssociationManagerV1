-- Update sp_TariffGroups_GetByTenantId to support scoping
CREATE   PROCEDURE sp_TariffGroups_GetByTenantId
    @TenantId INT,
    @AssociationId INT = NULL
AS
BEGIN
    SELECT * FROM TariffGroups 
    WHERE TenantId = @TenantId 
      AND (AssociationId = @AssociationId OR @AssociationId IS NULL OR @AssociationId = 0)
    ORDER BY Name;
END