using System;

namespace AssociationManager.Shared.Models;

public class AssociationProfile
{
    public int AssociationId { get; set; }
    public string? RegistrationNumber { get; set; }
    public DateTime? RegistrationDate { get; set; }
    public string? Address { get; set; }
    public string? City { get; set; }
    public string? State { get; set; }
    public string? Pincode { get; set; }
    public string? ContactEmail { get; set; }
    public string? ContactPhone { get; set; }
    public byte[]? Logo { get; set; }
    public string Status { get; set; } = "Active";
}
