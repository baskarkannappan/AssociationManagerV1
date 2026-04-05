using System;
using AssociationManager.Shared.Enums;

namespace AssociationManager.Shared.Models;

public class FineSettings
{
    public int FineSettingsId { get; set; }
    public int AssociationId { get; set; }
    public int TenantId { get; set; }
    public string StrategyType { get; set; } = "None"; // Matches FineStrategyType enum string
    public decimal FineValue { get; set; }
    public int GracePeriodDays { get; set; }
    public bool IsCompounding { get; set; }
    public string Frequency { get; set; } = "Monthly";
    public DateTime LastUpdated { get; set; } = DateTime.UtcNow;
    public string? LastUpdatedBy { get; set; }
}
