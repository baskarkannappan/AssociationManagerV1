using System;
using System.ComponentModel.DataAnnotations;

namespace AssociationManager.Shared.Models;

public class AssociationProfile
{
    public int AssociationId { get; set; }

    [Required(ErrorMessage = "Registration Number is required")]
    public string? RegistrationNumber { get; set; }

    [Required(ErrorMessage = "Registration Date is required")]
    public DateTime? RegistrationDate { get; set; }

    [Required(ErrorMessage = "Address is required")]
    public string? Address { get; set; }

    [Required(ErrorMessage = "City is required")]
    public string? City { get; set; }

    [Required(ErrorMessage = "State is required")]
    public string? State { get; set; }

    [Required(ErrorMessage = "Pincode is required")]
    [RegularExpression(@"^\d{6}$", ErrorMessage = "Pincode must be exactly 6 digits (e.g., 600019)")]
    public string? Pincode { get; set; }

    [Required(ErrorMessage = "Contact Email is required")]
    [EmailAddress(ErrorMessage = "Invalid email address format")]
    public string? ContactEmail { get; set; }

    [Required(ErrorMessage = "Contact Phone is required")]
    [RegularExpression(@"^\+91 [6-9]\d{9}$", ErrorMessage = "Mobile must be in Indian format: +91 9500037967")]
    public string? ContactPhone { get; set; }

    public byte[]? Logo { get; set; }
    public string Status { get; set; } = "Active";
}
