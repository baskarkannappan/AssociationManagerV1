# Role Access Matrix

This document outlines the menu visibility and access permissions for each role within the Association Manager application.

## Role Levels
- **System Admin**: 90
- **Association Admin**: 80
- **Asset Manager**: 60
- **User Manager**: 50
- **Finance Manager**: 40
- **Resident**: 10

## Navigation Menu Visibility

| Menu Item | Policy/Rule Name | Resident (10) | Finance Mgr (40) | User Mgr (50) | Asset Mgr (60) | Assoc Admin (80) | Sys Admin (90) |
| :--- | :--- | :---: | :---: | :---: | :---: | :---: | :---: |
| **Dashboard** | `_hasAccess` | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| **Assets** | `ShowMenu_Assets` | ✅ | ✅ | ❌ | ✅ | ✅ | ✅ |
| **User & Roles** | `ShowMenu_Users` | ❌ | ❌ | ✅ | ✅ | ✅ | ✅ |
| **Tariff Management** | `ShowMenu_Tariffs` | ❌ | ✅ | ❌ | ✅ | ✅ | ✅ |
| **Finance** | `ShowMenu_Finance` | ✅ | ✅ | ❌ | ❌ | ✅ | ✅ |
| **Advance Ledgers** | `ShowMenu_Advances` | ❌ | ✅ | ❌ | ❌ | ✅ | ✅ |
| **Reports** | `ShowMenu_Reports` | ❌ | ✅ | ❌ | ❌ | ✅ | ✅ |
| **My Wallet** | `ShowMenu_Wallet` | ✅ | ✅ | ❌ | ❌ | ✅ | ❌ |
| **Communication** | `ShowMenu_Broadcasts` | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| **Community** | `ShowMenu_Community` | ❌ | ❌ | ✅ | ✅ | ✅ | ✅ |
| **Governance** | `ShowMenu_Governance` | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| **Settings** | `ShowMenu_Settings` | ❌ | ❌ | ❌ | ❌ | ❌ | ✅ |
| **Platform Subscription**| `RequireAssocAdmin`| ❌ | ❌ | ❌ | ❌ | ✅ | ✅ |

### Key Logic Notes
1. **UserManager (50) Isolation**: Explicitly blocked from **Assets**, **Tariffs**, and **Finance** modules.
2. **AssetManager (60) Isolation**: Explicitly blocked from **Finance** and **Tariff Management** (though allowed in Assets).
3. **Finance Manager (40)**: Has access to all financial modules and tariffs but restricted from People/User management.
4. **My Wallet**: Hidden for System Admins.
5. **Settings**: Restricted strictly to System Admin (Level 90+).
