-- Update sp_Payments_GetByTenantId
CREATE   PROCEDURE sp_Payments_GetByTenantId
    @TenantId INT,
    @AssociationId INT = NULL
AS
BEGIN
    SELECT * FROM Payments 
    WHERE TenantId = @TenantId 
      AND (AssociationId = @AssociationId OR @AssociationId IS NULL OR @AssociationId = 0)
    ORDER BY CreatedDate DESC;
END