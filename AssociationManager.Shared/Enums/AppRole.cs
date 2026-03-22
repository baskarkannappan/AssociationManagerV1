namespace AssociationManager.Shared.Enums;

public static class AppRole
{
    public const string SystemAdmin = "SystemAdmin";
    public const string AssociationAdmin = "AssociationAdmin";
    public const string AssetManager = "AssetManager";
    public const string UserManager = "UserManager";
    public const string FinanceManager = "FinanceManager";
    public const string Resident = "Resident";

    // Corporate Specific Roles
    public const string PlatformAdmin = "PlatformAdmin";
    public const string CorporateManager = "CorporateManager";
    public const string SubscriptionManager = "SubscriptionManager";
    public const string GlobalUserManager = "GlobalUserManager";
    public const string CorporateAuditor = "CorporateAuditor";

    // Role Levels (Hierarchy)
    public const int LevelPlatformAdmin = 100;
    public const int LevelSystemAdmin = 90;
    public const int LevelGlobalUserManager = 90;
    public const int LevelCorporateManager = 80;
    public const int LevelAssociationAdmin = 80;
    public const int LevelSubscriptionManager = 70;
    public const int LevelAssetManager = 60;
    public const int LevelUserManager = 50;
    public const int LevelFinanceManager = 40;
    public const int LevelResident = 10;
    public const int LevelCorporateAuditor = 5;
    public const int LevelGuest = 0;

    public static int GetLevel(string? role) => role switch
    {
        PlatformAdmin => LevelPlatformAdmin,
        SystemAdmin => LevelSystemAdmin,
        GlobalUserManager => LevelGlobalUserManager,
        CorporateManager => LevelCorporateManager,
        AssociationAdmin => LevelAssociationAdmin,
        SubscriptionManager => LevelSubscriptionManager,
        AssetManager => LevelAssetManager,
        UserManager => LevelUserManager,
        FinanceManager => LevelFinanceManager,
        Resident => LevelResident,
        CorporateAuditor => LevelCorporateAuditor,
        _ => LevelGuest
    };

    public static readonly string[] All = { 
        PlatformAdmin, SystemAdmin, CorporateManager, SubscriptionManager, 
        GlobalUserManager, CorporateAuditor, AssociationAdmin, AssetManager, 
        UserManager, FinanceManager, Resident 
    };

    public static readonly string[] CorporateRolesArray = {
        PlatformAdmin, SystemAdmin, GlobalUserManager, CorporateManager, SubscriptionManager, CorporateAuditor
    };

    public static bool IsCorporateRole(string? role) => role switch
    {
        PlatformAdmin or SystemAdmin or GlobalUserManager or
        CorporateManager or SubscriptionManager or CorporateAuditor => true,
        _ => false
    };

    public static string[] GetCapabilities(string role) => role switch
    {
        PlatformAdmin => new[] { "Full Platform Control", "Create/Edit/Delete Associations", "Create/Edit/Delete Subscription Plans", "Map Plans to Associations", "Full User & Role Management" },
        SystemAdmin or GlobalUserManager => new[] { "User & Role Management", "Create/Edit/Delete Users", "Assign/Update Roles" },
        CorporateManager => new[] { "Create Associations", "Map Existing Subscription Plans" },
        SubscriptionManager => new[] { "Create/Update Subscription Plans", "View Associations" },
        CorporateAuditor => new[] { "View Only: Subscriptions & Plans", "View Only: Billing & Payments", "No Edit Permissions" },
        AssociationAdmin => new[] { "Association Management", "Asset Configuration", "Financial Authority", "User Administration", "Bulk Operations" },
        AssetManager => new[] { "Property & Unit Registry", "Hierarchy Management", "Operations & Work Orders", "Maintenance Tracking" },
        UserManager => new[] { "Resident Management", "Community Data Controls", "Occupancy Compliance", "Vehicle & Pet Registry" },
        FinanceManager => new[] { "Billing & Invoicing", "Payment Reconciliation", "Tax/Tariff Management", "Financial Reporting" },
        Resident => new[] { "Personal Property View", "Invoice History", "Maintenance Requests", "Profile Management" },
        _ => new[] { "Basic Dashboard Access" }
    };
}
