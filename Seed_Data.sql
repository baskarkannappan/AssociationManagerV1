-- REPOSITORY-WIDE SEED DATA SCRIPT
-- Generated for AssociationManageruat
SET NOCOUNT ON;
GO

-- 1. SCHEMAS (Ensure they exist)
IF NOT EXISTS (SELECT * FROM sys.schemas WHERE name = 'corp') EXEC('CREATE SCHEMA corp');
IF NOT EXISTS (SELECT * FROM sys.schemas WHERE name = 'assoc') EXEC('CREATE SCHEMA assoc');
GO

-- 2. SUBSCRIPTION PLANS
SET IDENTITY_INSERT [corp].[SubscriptionPlans] ON;
INSERT INTO [corp].[SubscriptionPlans] (PlanId, Name, BasePrice, PricePerAsset, IsActive) VALUES
(1, 'Basic', 1000.00, 10.00, 1),
(2, 'Premium', 5000.00, 25.00, 1),
(3, 'Enterprise', 10000.00, 50.00, 1);
SET IDENTITY_INSERT [corp].[SubscriptionPlans] OFF;
GO

-- 3. TENANTS
SET IDENTITY_INSERT [corp].[Tenants] ON;
INSERT INTO [corp].[Tenants] (TenantId, Name, Domain, IsActive, CreatedDate) VALUES
(1, 'Default Platform Tenant', 'platform.com', 1, GETUTCDATE());
SET IDENTITY_INSERT [corp].[Tenants] OFF;
GO

-- 4. ASSOCIATIONS
SET IDENTITY_INSERT [corp].[Associations] ON;
INSERT INTO [corp].[Associations] (AssociationId, TenantId, Name, IsActive, CreatedDate) VALUES
(1, 1, 'Springfield Gardens HOA', 1, GETUTCDATE());
SET IDENTITY_INSERT [corp].[Associations] OFF;
GO

-- 5. CORPORATE PLATFORM ACCOUNTS
SET IDENTITY_INSERT [corp].[PlatformAccounts] ON;
INSERT INTO [corp].[PlatformAccounts] (Id, TenantId, AccountName, Provider, IsActive) VALUES
(1, 1, 'Main Corporate Account', 'Razorpay', 1);
SET IDENTITY_INSERT [corp].[PlatformAccounts] OFF;
GO

-- 6. USERS
SET IDENTITY_INSERT [assoc].[Users] ON;
INSERT INTO [assoc].[Users] (UserId, TenantId, Email, Name, Role, IsActive, CreatedDate) VALUES
(1, 1, 'admin@springfield.com', 'Admin User', 'Admin', 1, GETUTCDATE()),
(2, 1, 'resident@springfield.com', 'John Doe', 'User', 1, GETUTCDATE());
SET IDENTITY_INSERT [assoc].[Users] OFF;
GO

-- 7. COMMITTEE ROLES
SET IDENTITY_INSERT [assoc].[CommitteeRoles] ON;
INSERT INTO [assoc].[CommitteeRoles] (RoleId, RoleName) VALUES
(1, 'President'),
(2, 'Secretary'),
(3, 'Treasurer'),
(4, 'Committee Member');
SET IDENTITY_INSERT [assoc].[CommitteeRoles] OFF;
GO

-- 8. AUTH WORKFLOWS
SET IDENTITY_INSERT [assoc].[AuthWorkflows] ON;
INSERT INTO [assoc].[AuthWorkflows] (WorkflowId, Name, WorkflowJson, Description) VALUES
(1, 'Default Approval', '{"steps": []}', 'Standard approval process for associations');
SET IDENTITY_INSERT [assoc].[AuthWorkflows] OFF;
GO

-- 9. ASSETS (Hierarchy)
SET IDENTITY_INSERT [assoc].[Assets] ON;
INSERT INTO [assoc].[Assets] (AssetId, ParentId, TenantId, AssociationId, Name, AssetType, IsActive, CreatedDate) VALUES
(1, NULL, 1, 1, 'Building A', 1, 1, GETUTCDATE()),
(2, 1, 1, 1, 'Unit 101', 2, 1, GETUTCDATE()),
(3, 1, 1, 1, 'Unit 102', 2, 1, GETUTCDATE());
SET IDENTITY_INSERT [assoc].[Assets] OFF;
GO

-- 10. PERSONS & OCCUPANCY
SET IDENTITY_INSERT [assoc].[Persons] ON;
INSERT INTO [assoc].[Persons] (PersonId, TenantId, AssociationId, FirstName, LastName, Email, IsActive) VALUES
(1, 1, 1, 'John', 'Doe', 'resident@springfield.com', 1);
SET IDENTITY_INSERT [assoc].[Persons] OFF;

INSERT INTO [assoc].[Occupancy] (AssetId, PersonId, TenantId, AssociationId, OccupancyType, IsPrimaryContact) VALUES
(2, 1, 1, 1, 1, 1); -- John Doe is Primary Owner of Unit 101
GO

-- 11. BILLING SETUP
SET IDENTITY_INSERT [assoc].[TariffGroups] ON;
INSERT INTO [assoc].[TariffGroups] (TariffGroupId, TenantId, Name, AssociationId) VALUES
(1, 1, 'Monthly Maintenance', 1);
SET IDENTITY_INSERT [assoc].[TariffGroups] OFF;

SET IDENTITY_INSERT [assoc].[TariffLayers] ON;
INSERT INTO [assoc].[TariffLayers] (TariffLayerId, TariffGroupId, TenantId, Name, BaseRate, Frequency, CalculationType) VALUES
(1, 1, 1, 'Flat Charge', 1500.00, 1, 1);
SET IDENTITY_INSERT [assoc].[TariffLayers] OFF;

-- Link Asset to Tariff
INSERT INTO [assoc].[AssetTariffs] (AssetId, TariffLayerId, CustomAmount, IsActive, IsRecurring) VALUES
(2, 1, NULL, 1, 1),
(3, 1, NULL, 1, 1);
GO

-- 12. FINE SETTINGS
SET IDENTITY_INSERT [assoc].[FineSettings] ON;
INSERT INTO [assoc].[FineSettings] (FineSettingsId, AssociationId, TenantId, StrategyType, FineValue, GracePeriodDays) VALUES
(1, 1, 1, 'Flat', 100.00, 5);
SET IDENTITY_INSERT [assoc].[FineSettings] OFF;
GO

-- 13. ASSOCIATION BANK DETAILS
INSERT INTO [assoc].[AssociationBankDetails] (AssociationId, TenantId, PrimaryAccountName, PrimaryAccountNumber, PrimaryIFSCCode, PrimaryBankName, CreatedBy) VALUES
(1, 1, 'Springfield Gardens HOA', '91901001234567', 'UTIB0001234', 'Axis Bank', 1);
GO
