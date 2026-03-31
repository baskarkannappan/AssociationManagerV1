-- Unit Registry Update Stored Procedures
-- This script adds the missing update procs for Occupancy, Vehicles, and Pets in the assoc schema.

-- 1. Occupancy Update
CREATE OR ALTER PROCEDURE assoc.sp_Occupancy_Update
    @OccupancyId INT,
    @AssetId INT,
    @PersonId INT,
    @TenantId INT,
    @AssociationId INT,
    @OccupancyType INT,
    @StartDate DATETIME,
    @EndDate DATETIME = NULL,
    @IsPrimaryContact BIT
AS
BEGIN
    UPDATE assoc.Occupancy
    SET AssetId = @AssetId,
        PersonId = @PersonId,
        TenantId = @TenantId,
        AssociationId = @AssociationId,
        OccupancyType = @OccupancyType,
        StartDate = @StartDate,
        EndDate = @EndDate,
        IsPrimaryContact = @IsPrimaryContact
    WHERE OccupancyId = @OccupancyId AND TenantId = @TenantId AND AssociationId = @AssociationId;
END
GO

-- 2. Vehicles Update
CREATE OR ALTER PROCEDURE assoc.sp_Vehicles_Update
    @VehicleId INT,
    @AssetId INT,
    @TenantId INT,
    @AssociationId INT,
    @Make NVARCHAR(100),
    @Model NVARCHAR(100),
    @LicensePlate NVARCHAR(50),
    @Color NVARCHAR(50) = NULL,
    @ParkingSlot NVARCHAR(100) = NULL,
    @IsActive BIT
AS
BEGIN
    UPDATE assoc.Vehicles
    SET AssetId = @AssetId,
        TenantId = @TenantId,
        AssociationId = @AssociationId,
        Make = @Make,
        Model = @Model,
        LicensePlate = @LicensePlate,
        Color = @Color,
        ParkingSlot = @ParkingSlot,
        IsActive = @IsActive
    WHERE VehicleId = @VehicleId AND TenantId = @TenantId AND AssociationId = @AssociationId;
END
GO

-- 3. Pets Update
CREATE OR ALTER PROCEDURE assoc.sp_Pets_Update
    @PetId INT,
    @AssetId INT,
    @TenantId INT,
    @AssociationId INT,
    @Name NVARCHAR(100),
    @Species NVARCHAR(100),
    @Breed NVARCHAR(100) = NULL,
    @TagNumber NVARCHAR(50) = NULL,
    @IsActive BIT
AS
BEGIN
    UPDATE assoc.Pets
    SET AssetId = @AssetId,
        TenantId = @TenantId,
        AssociationId = @AssociationId,
        Name = @Name,
        Species = @Species,
        Breed = @Breed,
        TagNumber = @TagNumber,
        IsActive = @IsActive
    WHERE PetId = @PetId AND TenantId = @TenantId AND AssociationId = @AssociationId;
END
GO
