CREATE   PROCEDURE [assoc].sp_Vehicles_Update
    @VehicleId INT,
    @TenantId INT,
    @AssociationId INT,
    @Make NVARCHAR(100),
    @Model NVARCHAR(100),
    @LicensePlate NVARCHAR(50),
    @Color NVARCHAR(50) = NULL,
    @ParkingSlot NVARCHAR(50) = NULL,
    @IsActive BIT
AS
BEGIN
    UPDATE Vehicles 
    SET Make = @Make, 
        Model = @Model, 
        LicensePlate = @LicensePlate, 
        Color = @Color, 
        ParkingSlot = @ParkingSlot, 
        IsActive = @IsActive 
    WHERE VehicleId = @VehicleId AND TenantId = @TenantId AND AssociationId = @AssociationId;
END