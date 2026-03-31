-- Unit Registry Update Stored Procedures
-- This script adds the missing update procs for Occupancy, Vehicles, and Pets in the assoc schema.

-- 1. Occupancy Update
CREATE   PROCEDURE assoc.sp_Occupancy_Update
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