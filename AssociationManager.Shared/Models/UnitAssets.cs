using System;

namespace AssociationManager.Shared.Models;

public class Vehicle
{
    public int VehicleId { get; set; }
    public int AssetId { get; set; } // Link to Unit
    public int TenantId { get; set; }
    public string Make { get; set; } = string.Empty;
    public string Model { get; set; } = string.Empty;
    public string LicensePlate { get; set; } = string.Empty;
    public string? Color { get; set; }
    public string? ParkingSlot { get; set; }
    public bool IsActive { get; set; } = true;
}

public class Pet
{
    public int PetId { get; set; }
    public int AssetId { get; set; } // Link to Unit
    public int TenantId { get; set; }
    public string Name { get; set; } = string.Empty;
    public string Species { get; set; } = string.Empty; // Dog, Cat, etc.
    public string? Breed { get; set; }
    public string? TagNumber { get; set; }
    public bool IsActive { get; set; } = true;
}
