# Developer API Mapping: AssociationManager.Corporate.Client

This document maps the UI pages and sections of the **Corporate Manager (Platform Admin Portal)** to their respective API endpoints and underlying SQL Stored Procedures.

## 1. Association & Instance Management

| Page / Section | UI File | Method | API Endpoint | Stored Procedure | Purpose |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **Associations List** | `Associations.razor` | `GET` | `api/associations` | `corp.sp_Associations_List` | Displays all associations onboarded under a specific corporate client. |
| **Create Association** | `Associations.razor` | `POST` | `api/associations` | `corp.sp_Associations_Create` | Seeds a new association instance with default settings and a new database entry. |
| **Update Association** | `Associations.razor` | `PUT` | `api/associations/{id}` | `corp.sp_Associations_Update` | Refines metadata and configuration for a managed association. |

## 2. Platform Billing & SaaS Subscriptions

| Page / Section | UI File | Method | API Endpoint | Stored Procedure | Purpose |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **Subscription Plans** | `SubscriptionManagement.razor` | `GET` | `api/subscription/plans` | `corp.sp_SubscriptionPlans_GetAll` | Manages available SaaS tiers (Base price + Per-unit price). |
| **Association Billing** | `SubscriptionManagement.razor` | `GET` | `api/subscription/{assocId}` | `corp.sp_Subscriptions_GetByAssociationId`| Retrieves the current subscription status and next billing date for an association. |
| **Platform Invoices** | `PlatformBilling.razor`| `GET` | `api/platform-billing`| `corp.sp_PlatformInvoices_Get` | Tracks corporate-level invoices charged to the association from the platform provider. |

## 3. Global User & Security Administration

| Page / Section | UI File | Method | API Endpoint | Stored Procedure | Purpose |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **Corporate Users** | `Users.razor` | `GET` | `api/users/corporate` | `corp.sp_Users_GetPaged` | Manages platform-level users (Corporate Auditors, System Admins). |
| **Role Assignment** | `Users.razor` | `POST` | `api/auth/assign-role` | `corp.sp_UserRoles_Upsert` | Grants specific corporate-level permissions to a platform user. |
| **System Settings** | `Settings.razor` | `GET` | `api/settings/corporate` | `corp.sp_CorporateSettings_Get` | Manages global platform configuration and white-labeling. |

---

### **Developer Notes:**
- All endpoints are managed through the shared `ApiService`.
- The `corp.` schema is exclusively used for platform-level operations and multi-tenant management.
- Authorization is strictly enforced using policies such as `RequirePlatformAdmin` and `RequireCorporateManager`.
