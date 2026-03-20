# Proposed Approach: API Separation for Corporate and Association

To complement the existing client separation, we will logically split the backend API into two distinct services while maintaining a shared database and data access layer.

## 1. Architectural Strategy

- **Two API Services**:
  - `AssociationManager.Corporate.Api`: Handles platform-wide management, multi-tenant oversight, subscriptions, and global security.
  - `AssociationManager.Api`: Handles association-specific business logic (maintenance, local community, association billing, etc.).
- **Shared Data Layer**: Both APIs will continue to use the existing `AssociationManager.Data`, `AssociationManager.Services`, and `AssociationManager.Shared` projects, ensuring data consistency and code reuse.
- **Gateway as a Router**: The `AssociationManager.Gateway` will act as the single entry point, routing requests to the correct backend based on the URL path.

## 2. Component Split

### **Corporate API (`AssociationManager.Corporate.Api`)**
- **Associations**: Create, delete, and list all tenants (associations).
- **Subscription Management**: Manage platform plans, global pricing, and association-level subscriptions.
- **Global User Management**: Handle platform-wide roles (System Admin, Corporate Manager).
- **Global Auth**: Shared authentication logic for platform-level access.

### **Association API (`AssociationManager.Api`)**
- **Assets**: Manage buildings, units, and equipment for a specific association.
- **Operations & Maintenance**: Handle work orders, service requests, and facility management.
- **Finance (Local)**: Association-specific ledger, invoicing for residents, and local tariffs.
- **Community (People)**: Manage residents, broadcasts, and local communications.

## 3. Implementation Steps

1.  **Project Initialization**: 
    - Duplicate `AssociationManager.Api` into a new project `AssociationManager.Corporate.Api`.
    - Assigned unique port (default: 7010).
2.  **Controller Cleanup**: 
    - Remove association-specific controllers from the Corporate API.
    - Remove platform-specific controllers (Subscriptions, Association Management) from the original API.
3.  **Gateway Update**: 
    - Update the Gateway routing configuration (or `Program.cs`) to direct `/api/corporate/*` to the new Corporate API.
4.  **Client Update**: 
    - Configure `Corporate.Client` to use the `/api/corporate/` endpoint prefix (or point directly to the Corporate API port if preferred).
5.  **PowerShell Synchronization**: 
    - Add the new Corporate API to `run-all.ps1` for one-click startup.

## 5. Premium Architecture Enhancements (Suggestions)

To make the platform even more robust and scalable, we can consider these advanced patterns:

- **Dedicated Identity Service**: Extract authentication into `AssociationManager.Identity`. This centralizes Google OAuth and JWT issuance, ensuring a single source of truth for user sessions across both clients and all APIs.
- **Background Worker Service**: Move long-running tasks (e.g., subscription renewal processing, monthly invoice generation, or broadcast dispatching) to a dedicated `AssociationManager.Worker` service. This keeps the APIs responsive.
- **Service Layer Modularization**: Split the monolithic `AssociationManager.Services` into:
  - `AssociationManager.Services.Corporate`: Logic for multi-tenant and platform management.
  - `AssociationManager.Services.Association`: Logic for day-to-day association operations.
  - `AssociationManager.Services.Core`: Shared abstractions and utility logic.
- **API Versioning**: Implement formal versioning (e.g., `/api/v1/...`) to allow future updates without breaking existing clients.
- **Health Checks & Monitoring**: Add standardized health endpoints for the Gateway to monitor the status of each backend service automatically.

## 6. Comparison Table

| Feature | Current (Monolith API) | Proposed (Separated) | Premium (Micro-Service Ready) |
| :--- | :--- | :--- | :--- |
| **Code Focus** | Mixed Corporate/Assoc | Isolated Domain Logic | Highly Granular & Focused |
| **Scalability** | Scale everything together | Scale Assoc vs Corp separately | Scale background tasks separately |
| **Security** | Shared security surface | Reduced attack surface | Centralized Identity Control |
| **Reliability** | One crash stops all | Only one domain impacted | Isolated failure domains |
