using AssociationManager.Shared.Enums;
using System.Collections.Generic;

namespace AssociationManager.Shared.Models;

public class TariffGroup
{
    public int TariffGroupId { get; set; }
    public int TenantId { get; set; }
    public string Name { get; set; } = string.Empty;
    public string? Description { get; set; }
    public List<TariffLayer> Layers { get; set; } = new();
}

public class TariffLayer
{
    public int TariffLayerId { get; set; }
    public int TariffGroupId { get; set; }
    public int TenantId { get; set; }
    public string Name { get; set; } = string.Empty;
    public decimal BaseRate { get; set; }
    public BillingFrequency Frequency { get; set; }
    public CalculationType CalculationType { get; set; }
    public string? AccountingCategory { get; set; }
}

public class AssetTariff
{
    public int AssetId { get; set; }
    public int TariffLayerId { get; set; }
    public decimal? CustomAmount { get; set; } // Override base rate
    public bool IsActive { get; set; } = true;
}

public class Transaction
{
    public long TransactionId { get; set; }
    public int TenantId { get; set; }
    public int AssetId { get; set; }
    public int? InvoiceId { get; set; }
    public int? PaymentId { get; set; }
    public string Type { get; set; } = "Debit"; // Debit, Credit
    public decimal Amount { get; set; }
    public string Category { get; set; } = "General";
    public string Description { get; set; } = string.Empty;
    public DateTime TransactionDate { get; set; } = DateTime.UtcNow;
}
