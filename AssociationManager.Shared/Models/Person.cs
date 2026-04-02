using System;

namespace AssociationManager.Shared.Models;

public class Person
{
    public int PersonId { get; set; }
    public int TenantId { get; set; }
    public int AssociationId { get; set; }
    public string FirstName { get; set; } = string.Empty;
    public string LastName { get; set; } = string.Empty;
    public string? Email { get; set; }
    public string? Phone { get; set; }
    public string? PhotoUrl { get; set; }
    public DateTime CreatedDate { get; set; } = DateTime.UtcNow;
    public bool IsActive { get; set; } = true;

    public string FullName => $"{FirstName} {LastName}";
}

public class Occupancy
{
    public int OccupancyId { get; set; }
    public int AssetId { get; set; } // Link to Unit
    public int PersonId { get; set; }
    public int TenantId { get; set; }
    public int AssociationId { get; set; }
    public OccupancyType OccupancyType { get; set; } // Owner, Resident, Tenant
    public DateTime? StartDate { get; set; }
    public DateTime? EndDate { get; set; }
    public bool IsPrimaryContact { get; set; }

    // Enriched properties for display
    public string? PersonName { get; set; }
    public string? Email { get; set; }
    public string? AssetName { get; set; }
}

public enum OccupancyType
{
    Owner = 1,
    Tenant = 2,
    Resident = 3,
    FamilyMember = 4,
    Staff = 5
}
