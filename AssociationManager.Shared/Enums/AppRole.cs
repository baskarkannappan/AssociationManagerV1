namespace AssociationManager.Shared.Enums;

public static class AppRole
{
    public const string SystemAdmin = "SystemAdmin";
    public const string AssociationAdmin = "AssociationAdmin";
    public const string AssetManager = "AssetManager";
    public const string UserManager = "UserManager";
    public const string FinanceManager = "FinanceManager";
    public const string Resident = "Resident";

    public static readonly string[] All = { SystemAdmin, AssociationAdmin, AssetManager, UserManager, FinanceManager, Resident };

    public static string[] GetCapabilities(string role) => role switch
    {
        SystemAdmin => new[] { "Full System Control", "Global Association Management", "Security Auditing", "Platform Settings" },
        AssociationAdmin => new[] { "Association Management", "Asset Configuration", "Financial Authority", "User Administration", "Bulk Operations" },
        AssetManager => new[] { "Property & Unit Registry", "Hierarchy Management", "Operations & Work Orders", "Maintenance Tracking" },
        UserManager => new[] { "Resident Management", "Community Data Controls", "Occupancy Compliance", "Vehicle & Pet Registry" },
        FinanceManager => new[] { "Billing & Invoicing", "Payment Reconciliation", "Tax/Tariff Management", "Financial Reporting" },
        Resident => new[] { "Personal Property View", "Invoice History", "Maintenance Requests", "Profile Management" },
        _ => new[] { "Basic Dashboard Access" }
    };
}
