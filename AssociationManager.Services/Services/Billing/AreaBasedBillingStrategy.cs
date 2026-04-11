using AssociationManager.Shared.Models;
using AssociationManager.Shared.Enums;
using System.Text.Json;

namespace AssociationManager.Services.Billing;

public class AreaBasedBillingStrategy : IBillingStrategy
{
    public CalculationType SupportedType => CalculationType.AreaBased;

    public decimal Calculate(Asset asset, TariffLayer tariff, AssetTariff assignment)
    {
        decimal rate = assignment.CustomAmount ?? tariff.BaseRate;
        decimal area = 0;

        // Try to extract Area from MetadataJson
        if (!string.IsNullOrEmpty(asset.MetadataJson))
        {
            try 
            {
                var meta = JsonSerializer.Deserialize<Dictionary<string, object>>(asset.MetadataJson);
                if (meta == null) return rate * area;

                var keys = new[] { "Area", "area", "TotalAreaSqFt", "sqft", "SquareFeet", "Size" };
                string? matchedKey = null;

                foreach (var k in keys)
                {
                    if (meta.ContainsKey(k))
                    {
                        matchedKey = k;
                        break;
                    }
                }

                if (matchedKey != null)
                {
                    var val = meta[matchedKey];
                    if (val is JsonElement je && je.ValueKind == JsonValueKind.Number)
                        area = je.GetDecimal();
                    else if (val != null)
                        decimal.TryParse(val.ToString(), out area);
                }
            }
            catch { /* Ignore parse errors for now */ }
        }

        return rate * area;
    }
}
