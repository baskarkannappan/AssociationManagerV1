using System;
using System.ComponentModel.DataAnnotations;
using AssociationManager.Shared.Enums;

namespace AssociationManager.Shared.Models;

public class FineSettings
{
    public int FineSettingsId { get; set; }
    public int AssociationId { get; set; }
    public int TenantId { get; set; }
    
    [Required]
    public string StrategyType { get; set; } = "None"; // Matches FineStrategyType enum string

    [Required(ErrorMessage = "Fine Value/Rate is required")]
    [Range(0.01, 1000000, ErrorMessage = "Please enter a valid rate/amount greater than 0")]
    public decimal FineValue { get; set; }

    [Required(ErrorMessage = "Grace Period is required")]
    [Range(0, 365, ErrorMessage = "Grace period must be between 0 and 365 days")]
    public int GracePeriodDays { get; set; }

    public bool IsCompounding { get; set; }
    public string Frequency { get; set; } = "Monthly";
    public DateTime? ActivationDate { get; set; }
    public DateTime LastUpdated { get; set; } = DateTime.UtcNow;
    public string? LastUpdatedBy { get; set; }
}

