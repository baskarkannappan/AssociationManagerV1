# Developer API Mapping: AssociationManager.Client

This document maps the UI pages and sections of the **Association Manager (Residential Portal)** to their respective API endpoints and underlying SQL Stored Procedures. This is intended to help developers understand the end-to-end data flow.

## 1. Core Financials & Billing

| Page / Section | UI File | Method | API Endpoint | Stored Procedure | Purpose |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **Billing (Recent Invoices)** | `Billing.razor` | `GET` | `api/finance/invoices` | `assoc.sp_Invoices_GetPaged` | Retrieves paginated and filtered list of bills for the association or unit. |
| **Advance Ledgers** | `AdvanceLedgers.razor` | `GET` | `api/finance/advances` | `assoc.sp_Payments_GetAdvancesPaged` | High-performance server-side paging for the advance payment audit trail. |
| **My Wallet** | `MyWallet.razor` | `GET` | `api/finance/advances` | `assoc.sp_Payments_GetAdvancesPaged` | Resident-specific transaction history for wallet top-ups. |
| **Batch Generation** | `Billing.razor` | `POST` | `api/finance/batch-generate` | `assoc.sp_Invoices_GenerateBatch` | Creates a new billing cycle by generating invoices for all units based on rules. |
| **Bank Details** | `Settings.razor` | `GET` | `api/finance/bank-details` | `assoc.sp_AssociationBankDetails_Get` | Retrieves QR codes and bank info for receipt generation. |

## 2. Asset & Resource Management

| Page / Section | UI File | Method | API Endpoint | Stored Procedure | Purpose |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **Asset Registry** | `Assets.razor` | `GET` | `api/assets/hierarchy` | `assoc.sp_Assets_GetHierarchy` | Loads the full recursive tree of properties, buildings, and units. |
| **Asset Details** | `Assets.razor` | `GET` | `api/assets/{id}` | `assoc.sp_Assets_GetById` | Fetches specific metadata for a selected unit or common area. |
| **Bulk Create** | `BulkCreateModal.razor` | `POST` | `api/assets/bulk` | `assoc.sp_Assets_BulkInsert` | Creates multiple assets (e.g., floors/units) from a template. |
| **Occupancy** | `OccupancyList.razor` | `GET` | `api/people/unit/{id}/occupants` | `assoc.sp_Occupancy_GetDetails` | Lists all residents mapped to a specific unit. |

## 3. Administration & Governance

| Page / Section | UI File | Method | API Endpoint | Stored Procedure | Purpose |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **User Management** | `Users.razor` | `GET` | `api/users` | `assoc.sp_Users_GetPaged` | Manages association-level users, roles, and current wallet balances. |
| **Tariff Configuration** | `TariffManagement.razor`| `GET` | `api/tariff` | `assoc.sp_Tariffs_Get` | Manages unit-wise maintenance rates and utility per-unit charges. |
| **Committee Management**| `Committee.razor` | `GET` | `api/governance/committee` | `assoc.sp_Committee_Get` | Manages the elected body of the association and their designations. |
| **Governance Documents**| `ByeLaw.razor` | `GET` | `api/governance/byelaw` | `assoc.sp_Governance_GetByeLaw` | Provides access to association bye-laws and official logos. |

## 4. Maintenance & Operations

| Page / Section | UI File | Method | API Endpoint | Stored Procedure | Purpose |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **Work Orders** | `Maintenance.razor` | `GET` | `api/operations/workorders` | `assoc.sp_WorkOrders_Get` | Lists all maintenance requests and service tasks. |
| **Communications** | `Broadcasts.razor` | `GET` | `api/communications/broadcasts`| `assoc.sp_Broadcasts_Get` | Lists system announcements and notices. |

---

### **Developer Notes:**
- All endpoints use the `ApiService` wrapper in the Blazor client.
- `TenantId` and `AssociationId` are automatically injected into search criteria via the `ITenantContext` in the service layer.
- Ensure the `assoc.` schema is used for all residential database operations.
