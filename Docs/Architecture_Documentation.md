# Association Manager V1 - Architecture Documentation

This document provides a comprehensive overview of the system architecture, component design, data flow, and database schema for the Association Manager application.

## 1. System Overview

Association Manager is a multi-tenant SaaS application designed to manage residential associations, including billing, communication, asset management, and governance.

### High-Level System Diagram

```mermaid
graph TD
    User((Association Admin / Resident)) -->|HTTPS| Gateway[YARP Gateway - Port 7000]
    
    subgraph "Frontend Layer"
        Gateway -->|Proxy| AssocClient[Association Client - Port 7001]
        Gateway -->|Proxy| CorpClient[Corporate Client - Port 7011]
    end

    subgraph "API Layer"
        Gateway -->|REST| AssocApi[Association API - Port 5001]
        Gateway -->|REST| CorpApi[Corporate API - Port 7010]
    end

    subgraph "Background & Integration"
        AssocApi -->|Queue| Worker[Background Worker - Hangfire]
        Worker -->|SMTP| Gmail[Gmail SMTP]
        AssocApi -->|REST| Razorpay[Razorpay API]
    end

    subgraph "Data Layer"
        AssocApi -->|Dapper| SQL[(SQL Server - AssociationManagerV1)]
        CorpApi -->|Dapper| SQL
        Worker -->|Dapper| SQL
    end
```

---

## 2. Component Architecture

### 2.1 Web Applications (Blazor WebAssembly)
- **Association Client**: Primary interface for Residents and Association Admins.
- **Corporate Client**: Internal dashboard for Platform Admins to manage tenants and plans.

### 2.2 API Layer (ASP.NET Core)
- **Association API**: Handles association-specific logic (Finance, Assets, Users).
- **Corporate API**: Handles platform-wide management (Tenants, Subscriptions).

### 2.3 Data Access Layer
- **Dapper**: Lightweight ORM for high-performance data access.
- **Repository Pattern**: Abstract data access logic from services.
- **Stored Procedures**: Encapsulates business logic within the database.

---

## 3. Database Schema (Draft ER Diagram)

> [!NOTE]
> This is a high-level representation of the core entities.

```mermaid
erDiagram
    TENANT ||--o{ ASSOCIATION : "owns"
    ASSOCIATION ||--o{ USER_ASSOCIATION : "has"
    USER ||--o{ USER_ASSOCIATION : "belongs to"
    
    ASSOCIATION ||--o{ ASSET : "manages"
    ASSOCIATION ||--o{ INVOICE : "issues"
    INVOICE ||--o{ INVOICE_LINE_ITEM : "contains"
    
    ASSOCIATION ||--o{ COMMUNICATION_LOG : "queues"
    
    TENANT {
        int TenantId PK
        string Name
        string Domain
    }
    
    ASSOCIATION {
        int AssociationId PK
        int TenantId FK
        string Name
    }
    
    USER {
        int UserId PK
        string Email
        string IdentityProviderId
    }
    
    INVOICE {
        int InvoiceId PK
        int AssociationId FK
        int MemberId FK
        decimal Amount
        string Status
    }
    
    COMMUNICATION_LOG {
        int LogId PK
        int AssociationId FK
        string RecipientEmail
        int Status
    }
```

---

## 4. Page to API Mapping (Core Features)

## 4. Page to API to DB Mapping Table

This table comprehensive maps each UI page in the Blazor Client to its corresponding API, Service, Repository, and Database interactions.

| Page | API Controller | Core Service | Repository | Stored Procedure or Table |
| :--- | :--- | :--- | :--- | :--- |
| **Finance (Billing)** | `FinanceController` | `FinanceService` | `InvoiceRepository` | `assoc.sp_Invoices_CreateBatch` |
| **Commit Batch** | `FinanceController` | `FinanceService` | `BillingBatchRepository` | `assoc.sp_BillingBatch_UpdateStatus` |
| **Assets** | `AssetController` | `AssetService` | `AssetRepository` | `assoc.sp_Assets_GetByAssociation` |
| **Bulk Asset Create** | `AssetController` | `AssetService` | `AssetRepository` | `assoc.sp_Assets_Create` |
| **Users** | `UserController` | `AssocUserService` | `AssocUserRepository` | `assoc.sp_Users_GetByAssociationId` |
| **People/Occupancy** | `PeopleController` | `PeopleService` | `OccupancyRepository` | `assoc.sp_Occupancy_GetByAssetId` |
| **Email Queue** | `CommunicationController` | `EmailDispatchJob` | `CommunicationRepository` | `assoc.sp_CommunicationLogs_GetByAssociation` |
| **Payments** | `PaymentsController` | `PaymentServiceV2` | `PaymentRepository` | `assoc.sp_Transactions_Create` |
| **Razorpay Verify** | `PaymentsController` | `PaymentServiceV2` | `RazorpayRepository` | `assoc.sp_PaymentTransactions_Update` |
| **Dashboard** | `DashboardController` | `DashboardService` | `DashboardRepository` | `assoc.sp_Dashboard_GetStats` |
| **Settings** | `AssociationController` | `AssociationService` | `AssociationRepository` | `corp.sp_Associations_Update` |
| **Fine Settings** | `FinanceController` | `FineService` | `FineRepository` | `assoc.sp_FineSettings_Upsert` |
| **Maintenance** | `OperationsController` | `OperationsService` | `WorkOrderRepository` | `assoc.sp_WorkOrders_GetAll` |
| **My Wallet** | `FinanceController` | `FinanceService` | `PaymentRepository` | `assoc.sp_Transactions_GetBalance` |

---

## 5. Detailed Sequence Diagrams

### 5.1 Billing Batch Finalization & Email Dispatch
This diagram illustrates the flow when a billing batch is finalized and emails are dispatched.

```mermaid
sequenceDiagram
    participant Admin as Association Admin
    participant Client as Blazor Client
    participant API as Association API
    participant DB as SQL Server
    participant Worker as Background Worker
    participant Gmail as SMTP Server

    Admin->>Client: Click "Post to Ledger"
    Client->>API: POST /api/finance/batch/finalize
    API->>DB: Update Invoice Status (assoc.Invoices)
    API->>DB: Insert into assoc.CommunicationLogs (Status: Posted)
    API-->>Client: Success Response
    
    Note over Worker, DB: Hangfire Polling (Scheduled)
    
    Worker->>DB: Fetch Pending Emails (Status: Posted)
    DB-->>Worker: List of logs
    
    loop Each Email
        Worker->>Worker: Generate HTML from Template
        Worker->>Gmail: Send Email (SMTP)
        Worker->>DB: Update Status (Success / Failure)
    end
```

### 5.2 Payment Verification (Razorpay)
This diagram illustrates the flow when a resident makes a payment via Razorpay.

```mermaid
sequenceDiagram
    participant User as Resident
    participant Client as Blazor Client
    participant Gateway as Razorpay Checkout
    participant API as Association API
    participant DB as SQL Server

    User->>Client: Click "Pay Now"
    Client->>API: POST /api/payments/create-order
    API->>Gateway: Create RZP Order
    Gateway-->>API: order_id
    API-->>Client: order_id
    Client->>Gateway: Display Checkout UI
    User->>Gateway: Enters Payment Info
    Gateway-->>Client: razorpay_payment_id, signature
    Client->>API: POST /api/payments/verify
    API->>Gateway: Verify Signature
    API->>DB: Insert into assoc.PaymentTransactions (Success)
    API->>DB: Update assoc.Invoices (Status: Paid)
    API-->>Client: Payment Success
```

---

## 6. Class Hierachy (Core Services)

```mermaid
classDiagram
    class IFinanceService {
        +GetInvoiceByIdAsync()
        +GetPagedInvoicesAsync()
        +CommitBatchAsync()
    }
    class IAssetService {
        +GetHierarchyAsync()
        +CreateAsync()
    }
    class IPeopleService {
        +GetOccupancyByUnitAsync()
        +AddOccupantAsync()
    }
    class IEmailTemplateService {
        +GenerateInvoiceHtmlAsync()
    }
    
    IFinanceService ..> IInvoiceRepository : uses
    IFinanceService ..> IPaymentRepository : uses
    IFinanceService ..> IEmailTemplateService : uses
    
    IAssetService ..> IAssetRepository : uses
    IAssetService ..> IOccupancyRepository : uses
    
    IPeopleService ..> IPersonRepository : uses
    IPeopleService ..> IOccupancyRepository : uses
```

---

## 7. Database Detail (ER Diagram)

This ER diagram illustrates the core entity relationships based on the SQL project schema.

```mermaid
erDiagram
    TENANT ||--o{ ASSOCIATION : "owns"
    ASSOCIATION ||--o{ USER_ASSOCIATION : "has"
    USER ||--o{ USER_ASSOCIATION : "belongs to"
    
    ASSOCIATION ||--o{ ASSET : "manages"
    ASSOCIATION ||--o{ INVOICE : "issues"
    INVOICE ||--o{ INVOICE_LINE_ITEM : "contains"
    
    ASSOCIATION ||--o{ COMMUNICATION_LOG : "queues"
    ASSOCIATION ||--o{ ASSET_TARIFF : "configures"
    
    ASSET ||--o{ ASSET_TARIFF : "assigned to"
    ASSET ||--o{ TRANSACTION : "ledger"
    
    INVOICE ||--o{ TRANSACTION : "linked to"
    PAYMENT ||--o{ TRANSACTION : "linked to"
    
    TENANT {
        int TenantId PK
        string Name
    }
    
    ASSOCIATION {
        int AssociationId PK
        int TenantId FK
        string Name
    }
    
    INVOICE {
        int InvoiceId PK
        int AssociationId FK
        int MemberId FK
        decimal Amount
        string Status
    }
    
    COMMUNICATION_LOG {
        int LogId PK
        int AssociationId FK
        string RecipientEmail
        int Status
    }
    
    TRANSACTION {
        int TransactionId PK
        int AssetId FK
        decimal Amount
        string Type
        string Category
    }
```
