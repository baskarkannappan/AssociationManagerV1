CREATE   PROCEDURE assoc.sp_Vehicles_Delete @Id INT, @TenantId INT, @AssociationId INT AS 
BEGIN 
    DELETE FROM assoc.Vehicles 
    WHERE VehicleId = @Id AND AssociationId = @AssociationId; 
END