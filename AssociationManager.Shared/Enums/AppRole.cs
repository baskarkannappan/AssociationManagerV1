using System.Collections.Generic;
using System.Linq;
using System.Security.Claims;

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

    public static int GetLevel(string? role) => (role?.Trim().ToLowerInvariant().Replace(" ", "")) switch
    {
        "platformadmin" => LevelPlatformAdmin,
        "systemadmin" => LevelSystemAdmin,
        "globalusermanager" => LevelGlobalUserManager,
        "corporatemanager" => LevelCorporateManager,
        "associationadmin" => LevelAssociationAdmin,
        "subscriptionmanager" => LevelSubscriptionManager,
        "assetmanager" => LevelAssetManager,
        "usermanager" => LevelUserManager,
        "financemanager" => LevelFinanceManager,
        "resident" => LevelResident,
        "corporateauditor" => LevelCorporateAuditor,
        _ => LevelGuest
    };

    public static int GetMaxLevel(IEnumerable<Claim> claims)
    {
        // Collect all potential roles from various claim types
        var roles = claims.Where(c => 
            c.Type == "role" || 
            c.Type == ClaimTypes.Role || 
            c.Type == "http://schemas.microsoft.com/ws/2008/06/identity/claims/role" ||
            c.Type == "ContextRole"
        ).Select(c => c.Value).ToList();

        if (!roles.Any()) return LevelGuest;

        // Return the highest level found across all roles
        return roles.Select(GetLevel).Max();
    }

    public static string GetHighestRole(IEnumerable<Claim> claims)
    {
        var roles = claims.Where(c => c.Type == "role" || c.Type == ClaimTypes.Role)
                          .Select(c => c.Value).ToList();
        
        if (!roles.Any()) return "Guest";
        
        return roles.OrderByDescending(GetLevel).First();
    }

    public static string[] GetRoleHierarchy(string? rolesCsv)
    {
        if (string.IsNullOrEmpty(rolesCsv)) return new[] { "Guest" };
        
        return rolesCsv.Split(',', StringSplitOptions.RemoveEmptyEntries | StringSplitOptions.TrimEntries)
                       .OrderByDescending(GetLevel)
                       .ToArray();
    }

    public static readonly string[] All = { 
        PlatformAdmin, SystemAdmin, CorporateManager, SubscriptionManager, 
        GlobalUserManager, CorporateAuditor, AssociationAdmin, AssetManager, 
        UserManager, FinanceManager, Resident 
    };

    public static readonly string[] CorporateRolesArray = {
        PlatformAdmin, SystemAdmin, GlobalUserManager, CorporateManager, SubscriptionManager, CorporateAuditor
    };

    public static readonly string[] AssociationRolesArray = {
        AssociationAdmin, AssetManager, UserManager, FinanceManager, Resident
    };

    public static bool IsCorporateRole(string? role) => role switch
    {
        PlatformAdmin or SystemAdmin or GlobalUserManager or
        CorporateManager or SubscriptionManager or CorporateAuditor => true,
        _ => false
    };

    public static bool IsAssociationRole(string? role) => role switch
    {
        AssociationAdmin or AssetManager or UserManager or FinanceManager or Resident => true,
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
