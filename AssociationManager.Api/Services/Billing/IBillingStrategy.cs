using AssociationManager.Shared.Models;
using AssociationManager.Shared.Enums;

namespace AssociationManager.Api.Services.Billing;

public interface IBillingStrategy
{
    CalculationType SupportedType { get; }
    decimal Calculate(Asset asset, TariffLayer tariff, AssetTariff assignment);
}
