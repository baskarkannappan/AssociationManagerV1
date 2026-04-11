using AssociationManager.Shared.Models;
using AssociationManager.Shared.Enums;

namespace AssociationManager.Services.Billing;

public class FixedBillingStrategy : IBillingStrategy
{
    public CalculationType SupportedType => CalculationType.Fixed;

    public decimal Calculate(Asset asset, TariffLayer tariff, AssetTariff assignment)
    {
        // Use custom override if specified, otherwise base rate
        return assignment.CustomAmount ?? tariff.BaseRate;
    }
}
