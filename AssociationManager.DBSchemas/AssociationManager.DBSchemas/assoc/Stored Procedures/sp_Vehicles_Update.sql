-- 2. Vehicles Update
CREATE   PROCEDURE assoc.sp_Vehicles_Update
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