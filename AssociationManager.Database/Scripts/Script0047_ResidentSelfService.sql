-- Script0047_ResidentSelfService.sql
-- Missing Stored Procedures for Resident Self-Service

PRINT 'Creating assoc.sp_Occupancy_GetById'
GO
CREATE OR ALTER PROCEDURE assoc.sp_Occupancy_GetById
    @Id INT,
    @TenantId INT,
    @AssociationId INT
AS
BEGIN
    SELECT * FROM assoc.Occupancy 
    WHERE OccupancyId = @Id AND TenantId = @TenantId AND AssociationId = @AssociationId;
END;
GO

PRINT 'Creating assoc.sp_Vehicles_GetById'
GO
CREATE OR ALTER PROCEDURE assoc.sp_Vehicles_GetById
    @Id INT,
    @TenantId INT,
    @AssociationId INT
AS
BEGIN
    SELECT * FROM assoc.Vehicles 
    WHERE VehicleId = @Id AND TenantId = @TenantId AND AssociationId = @AssociationId;
END;
GO

PRINT 'Creating assoc.sp_Pets_GetById'
GO
CREATE OR ALTER PROCEDURE assoc.sp_Pets_GetById
    @Id INT,
    @TenantId INT,
    @AssociationId INT
AS
BEGIN
    SELECT * FROM assoc.Pets 
    WHERE PetId = @Id AND TenantId = @TenantId AND AssociationId = @AssociationId;
END;
GO
