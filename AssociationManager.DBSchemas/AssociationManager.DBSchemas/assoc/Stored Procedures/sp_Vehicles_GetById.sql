CREATE   PROCEDURE assoc.sp_Vehicles_GetById
    @Id INT,
    @TenantId INT,
    @AssociationId INT
AS
BEGIN
    SELECT * FROM assoc.Vehicles 
    WHERE VehicleId = @Id AND TenantId = @TenantId AND AssociationId = @AssociationId;
END;