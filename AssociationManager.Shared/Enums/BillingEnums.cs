namespace AssociationManager.Shared.Enums;

public enum BillingFrequency
{
    Monthly,
    Quarterly,
    HalfYearly,
    Yearly,
    AdHoc
}

public enum CalculationType
{
    Fixed,
    AreaBased,
    QuantityBased,
    Tiered
}

public enum FineStrategyType
{
    None,
    Percentage,
    FlatAmount,
    OneTimeFlat,
    OneTimePercentage
}
