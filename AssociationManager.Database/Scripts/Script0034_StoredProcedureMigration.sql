-- Corporate Procedures
-- Corporate Procedures
IF EXISTS (SELECT * FROM sys.procedures WHERE schema_id = SCHEMA_ID('dbo') AND name = 'sp_Tenants_GetById') 
   AND NOT EXISTS (SELECT * FROM sys.procedures WHERE schema_id = SCHEMA_ID('corp') AND name = 'sp_Tenants_GetById')
   ALTER SCHEMA corp TRANSFER dbo.sp_Tenants_GetById;

IF EXISTS (SELECT * FROM sys.procedures WHERE schema_id = SCHEMA_ID('dbo') AND name = 'sp_Tenants_GetAll') 
   AND NOT EXISTS (SELECT * FROM sys.procedures WHERE schema_id = SCHEMA_ID('corp') AND name = 'sp_Tenants_GetAll')
   ALTER SCHEMA corp TRANSFER dbo.sp_Tenants_GetAll;

IF EXISTS (SELECT * FROM sys.procedures WHERE schema_id = SCHEMA_ID('dbo') AND name = 'sp_Tenants_Create') 
   AND NOT EXISTS (SELECT * FROM sys.procedures WHERE schema_id = SCHEMA_ID('corp') AND name = 'sp_Tenants_Create')
   ALTER SCHEMA corp TRANSFER dbo.sp_Tenants_Create;

IF EXISTS (SELECT * FROM sys.procedures WHERE schema_id = SCHEMA_ID('dbo') AND name = 'sp_Tenants_Update') 
   AND NOT EXISTS (SELECT * FROM sys.procedures WHERE schema_id = SCHEMA_ID('corp') AND name = 'sp_Tenants_Update')
   ALTER SCHEMA corp TRANSFER dbo.sp_Tenants_Update;


IF EXISTS (SELECT * FROM sys.procedures WHERE schema_id = SCHEMA_ID('dbo') AND name = 'sp_Associations_GetById') 
   AND NOT EXISTS (SELECT * FROM sys.procedures WHERE schema_id = SCHEMA_ID('corp') AND name = 'sp_Associations_GetById')
   ALTER SCHEMA corp TRANSFER dbo.sp_Associations_GetById;

IF EXISTS (SELECT * FROM sys.procedures WHERE schema_id = SCHEMA_ID('dbo') AND name = 'sp_Associations_GetAll') 
   AND NOT EXISTS (SELECT * FROM sys.procedures WHERE schema_id = SCHEMA_ID('corp') AND name = 'sp_Associations_GetAll')
   ALTER SCHEMA corp TRANSFER dbo.sp_Associations_GetAll;

IF EXISTS (SELECT * FROM sys.procedures WHERE schema_id = SCHEMA_ID('dbo') AND name = 'sp_Associations_GetAllByTenantId') 
   AND NOT EXISTS (SELECT * FROM sys.procedures WHERE schema_id = SCHEMA_ID('corp') AND name = 'sp_Associations_GetAllByTenantId')
   ALTER SCHEMA corp TRANSFER dbo.sp_Associations_GetAllByTenantId;

IF EXISTS (SELECT * FROM sys.procedures WHERE schema_id = SCHEMA_ID('dbo') AND name = 'sp_Associations_Create') 
   AND NOT EXISTS (SELECT * FROM sys.procedures WHERE schema_id = SCHEMA_ID('corp') AND name = 'sp_Associations_Create')
   ALTER SCHEMA corp TRANSFER dbo.sp_Associations_Create;

IF EXISTS (SELECT * FROM sys.procedures WHERE schema_id = SCHEMA_ID('dbo') AND name = 'sp_Associations_Update') 
   AND NOT EXISTS (SELECT * FROM sys.procedures WHERE schema_id = SCHEMA_ID('corp') AND name = 'sp_Associations_Update')
   ALTER SCHEMA corp TRANSFER dbo.sp_Associations_Update;

IF EXISTS (SELECT * FROM sys.procedures WHERE schema_id = SCHEMA_ID('dbo') AND name = 'sp_Associations_Delete') 
   AND NOT EXISTS (SELECT * FROM sys.procedures WHERE schema_id = SCHEMA_ID('corp') AND name = 'sp_Associations_Delete')
   ALTER SCHEMA corp TRANSFER dbo.sp_Associations_Delete;

IF EXISTS (SELECT * FROM sys.procedures WHERE schema_id = SCHEMA_ID('dbo') AND name = 'sp_Associations_GetByUserId') 
   AND NOT EXISTS (SELECT * FROM sys.procedures WHERE schema_id = SCHEMA_ID('corp') AND name = 'sp_Associations_GetByUserId')
   ALTER SCHEMA corp TRANSFER dbo.sp_Associations_GetByUserId;


IF EXISTS (SELECT * FROM sys.procedures WHERE schema_id = SCHEMA_ID('dbo') AND name = 'sp_Subscriptions_GetByAssociationId') 
   AND NOT EXISTS (SELECT * FROM sys.procedures WHERE schema_id = SCHEMA_ID('corp') AND name = 'sp_Subscriptions_GetByAssociationId')
   ALTER SCHEMA corp TRANSFER dbo.sp_Subscriptions_GetByAssociationId;

IF EXISTS (SELECT * FROM sys.procedures WHERE schema_id = SCHEMA_ID('dbo') AND name = 'sp_Subscriptions_Upsert') 
   AND NOT EXISTS (SELECT * FROM sys.procedures WHERE schema_id = SCHEMA_ID('corp') AND name = 'sp_Subscriptions_Upsert')
   ALTER SCHEMA corp TRANSFER dbo.sp_Subscriptions_Upsert;

IF EXISTS (SELECT * FROM sys.procedures WHERE schema_id = SCHEMA_ID('dbo') AND name = 'sp_SubscriptionPlans_GetAll') 
   AND NOT EXISTS (SELECT * FROM sys.procedures WHERE schema_id = SCHEMA_ID('corp') AND name = 'sp_SubscriptionPlans_GetAll')
   ALTER SCHEMA corp TRANSFER dbo.sp_SubscriptionPlans_GetAll;

IF EXISTS (SELECT * FROM sys.procedures WHERE schema_id = SCHEMA_ID('dbo') AND name = 'sp_SubscriptionPlans_Upsert') 
   AND NOT EXISTS (SELECT * FROM sys.procedures WHERE schema_id = SCHEMA_ID('corp') AND name = 'sp_SubscriptionPlans_Upsert')
   ALTER SCHEMA corp TRANSFER dbo.sp_SubscriptionPlans_Upsert;


IF EXISTS (SELECT * FROM sys.procedures WHERE schema_id = SCHEMA_ID('dbo') AND name = 'sp_Users_GetById') 
   AND NOT EXISTS (SELECT * FROM sys.procedures WHERE schema_id = SCHEMA_ID('corp') AND name = 'sp_Users_GetById')
   ALTER SCHEMA corp TRANSFER dbo.sp_Users_GetById;

IF EXISTS (SELECT * FROM sys.procedures WHERE schema_id = SCHEMA_ID('dbo') AND name = 'sp_Users_GetByGoogleId') 
   AND NOT EXISTS (SELECT * FROM sys.procedures WHERE schema_id = SCHEMA_ID('corp') AND name = 'sp_Users_GetByGoogleId')
   ALTER SCHEMA corp TRANSFER dbo.sp_Users_GetByGoogleId;

IF EXISTS (SELECT * FROM sys.procedures WHERE schema_id = SCHEMA_ID('dbo') AND name = 'sp_Users_GetByEmail') 
   AND NOT EXISTS (SELECT * FROM sys.procedures WHERE schema_id = SCHEMA_ID('corp') AND name = 'sp_Users_GetByEmail')
   ALTER SCHEMA corp TRANSFER dbo.sp_Users_GetByEmail;

IF EXISTS (SELECT * FROM sys.procedures WHERE schema_id = SCHEMA_ID('dbo') AND name = 'sp_Users_GetByTenantId') 
   AND NOT EXISTS (SELECT * FROM sys.procedures WHERE schema_id = SCHEMA_ID('corp') AND name = 'sp_Users_GetByTenantId')
   ALTER SCHEMA corp TRANSFER dbo.sp_Users_GetByTenantId;

IF EXISTS (SELECT * FROM sys.procedures WHERE schema_id = SCHEMA_ID('dbo') AND name = 'sp_Users_Create') 
   AND NOT EXISTS (SELECT * FROM sys.procedures WHERE schema_id = SCHEMA_ID('corp') AND name = 'sp_Users_Create')
   ALTER SCHEMA corp TRANSFER dbo.sp_Users_Create;

IF EXISTS (SELECT * FROM sys.procedures WHERE schema_id = SCHEMA_ID('dbo') AND name = 'sp_Users_Update') 
   AND NOT EXISTS (SELECT * FROM sys.procedures WHERE schema_id = SCHEMA_ID('corp') AND name = 'sp_Users_Update')
   ALTER SCHEMA corp TRANSFER dbo.sp_Users_Update;


IF EXISTS (SELECT * FROM sys.procedures WHERE schema_id = SCHEMA_ID('dbo') AND name = 'sp_UserAssociations_CheckExists') 
   AND NOT EXISTS (SELECT * FROM sys.procedures WHERE schema_id = SCHEMA_ID('corp') AND name = 'sp_UserAssociations_CheckExists')
   ALTER SCHEMA corp TRANSFER dbo.sp_UserAssociations_CheckExists;

IF EXISTS (SELECT * FROM sys.procedures WHERE schema_id = SCHEMA_ID('dbo') AND name = 'sp_UserAssociations_Upsert') 
   AND NOT EXISTS (SELECT * FROM sys.procedures WHERE schema_id = SCHEMA_ID('corp') AND name = 'sp_UserAssociations_Upsert')
   ALTER SCHEMA corp TRANSFER dbo.sp_UserAssociations_Upsert;

IF EXISTS (SELECT * FROM sys.procedures WHERE schema_id = SCHEMA_ID('dbo') AND name = 'sp_UserAssociations_GetRole') 
   AND NOT EXISTS (SELECT * FROM sys.procedures WHERE schema_id = SCHEMA_ID('corp') AND name = 'sp_UserAssociations_GetRole')
   ALTER SCHEMA corp TRANSFER dbo.sp_UserAssociations_GetRole;

IF EXISTS (SELECT * FROM sys.procedures WHERE schema_id = SCHEMA_ID('dbo') AND name = 'sp_UserAssociations_Delete') 
   AND NOT EXISTS (SELECT * FROM sys.procedures WHERE schema_id = SCHEMA_ID('corp') AND name = 'sp_UserAssociations_Delete')
   ALTER SCHEMA corp TRANSFER dbo.sp_UserAssociations_Delete;


IF EXISTS (SELECT * FROM sys.procedures WHERE schema_id = SCHEMA_ID('dbo') AND name = 'sp_AuditLogs_Create') 
   AND NOT EXISTS (SELECT * FROM sys.procedures WHERE schema_id = SCHEMA_ID('corp') AND name = 'sp_AuditLogs_Create')
   ALTER SCHEMA corp TRANSFER dbo.sp_AuditLogs_Create;

IF EXISTS (SELECT * FROM sys.procedures WHERE schema_id = SCHEMA_ID('dbo') AND name = 'sp_AuditLogs_GetByTenantId') 
   AND NOT EXISTS (SELECT * FROM sys.procedures WHERE schema_id = SCHEMA_ID('corp') AND name = 'sp_AuditLogs_GetByTenantId')
   ALTER SCHEMA corp TRANSFER dbo.sp_AuditLogs_GetByTenantId;

IF EXISTS (SELECT * FROM sys.procedures WHERE schema_id = SCHEMA_ID('dbo') AND name = 'sp_RefreshTokens_GetByToken') 
   AND NOT EXISTS (SELECT * FROM sys.procedures WHERE schema_id = SCHEMA_ID('corp') AND name = 'sp_RefreshTokens_GetByToken')
   ALTER SCHEMA corp TRANSFER dbo.sp_RefreshTokens_GetByToken;

IF EXISTS (SELECT * FROM sys.procedures WHERE schema_id = SCHEMA_ID('dbo') AND name = 'sp_RefreshTokens_Upsert') 
   AND NOT EXISTS (SELECT * FROM sys.procedures WHERE schema_id = SCHEMA_ID('corp') AND name = 'sp_RefreshTokens_Upsert')
   ALTER SCHEMA corp TRANSFER dbo.sp_RefreshTokens_Upsert;

IF EXISTS (SELECT * FROM sys.procedures WHERE schema_id = SCHEMA_ID('dbo') AND name = 'sp_RefreshTokens_Delete') 
   AND NOT EXISTS (SELECT * FROM sys.procedures WHERE schema_id = SCHEMA_ID('corp') AND name = 'sp_RefreshTokens_Delete')
   ALTER SCHEMA corp TRANSFER dbo.sp_RefreshTokens_Delete;


-- Association Procedures
IF EXISTS (SELECT * FROM sys.procedures WHERE schema_id = SCHEMA_ID('dbo') AND name = 'sp_Assets_GetById') 
   AND NOT EXISTS (SELECT * FROM sys.procedures WHERE schema_id = SCHEMA_ID('assoc') AND name = 'sp_Assets_GetById')
   ALTER SCHEMA assoc TRANSFER dbo.sp_Assets_GetById;

IF EXISTS (SELECT * FROM sys.procedures WHERE schema_id = SCHEMA_ID('dbo') AND name = 'sp_Assets_GetAll') 
   AND NOT EXISTS (SELECT * FROM sys.procedures WHERE schema_id = SCHEMA_ID('assoc') AND name = 'sp_Assets_GetAll')
   ALTER SCHEMA assoc TRANSFER dbo.sp_Assets_GetAll;

IF EXISTS (SELECT * FROM sys.procedures WHERE schema_id = SCHEMA_ID('dbo') AND name = 'sp_Assets_Create') 
   AND NOT EXISTS (SELECT * FROM sys.procedures WHERE schema_id = SCHEMA_ID('assoc') AND name = 'sp_Assets_Create')
   ALTER SCHEMA assoc TRANSFER dbo.sp_Assets_Create;

IF EXISTS (SELECT * FROM sys.procedures WHERE schema_id = SCHEMA_ID('dbo') AND name = 'sp_Assets_Update') 
   AND NOT EXISTS (SELECT * FROM sys.procedures WHERE schema_id = SCHEMA_ID('assoc') AND name = 'sp_Assets_Update')
   ALTER SCHEMA assoc TRANSFER dbo.sp_Assets_Update;

IF EXISTS (SELECT * FROM sys.procedures WHERE schema_id = SCHEMA_ID('dbo') AND name = 'sp_Assets_Delete') 
   AND NOT EXISTS (SELECT * FROM sys.procedures WHERE schema_id = SCHEMA_ID('assoc') AND name = 'sp_Assets_Delete')
   ALTER SCHEMA assoc TRANSFER dbo.sp_Assets_Delete;

IF EXISTS (SELECT * FROM sys.procedures WHERE schema_id = SCHEMA_ID('dbo') AND name = 'sp_Assets_GetTree') 
   AND NOT EXISTS (SELECT * FROM sys.procedures WHERE schema_id = SCHEMA_ID('assoc') AND name = 'sp_Assets_GetTree')
   ALTER SCHEMA assoc TRANSFER dbo.sp_Assets_GetTree;


IF EXISTS (SELECT * FROM sys.procedures WHERE schema_id = SCHEMA_ID('dbo') AND name = 'sp_Persons_GetById') 
   AND NOT EXISTS (SELECT * FROM sys.procedures WHERE schema_id = SCHEMA_ID('assoc') AND name = 'sp_Persons_GetById')
   ALTER SCHEMA assoc TRANSFER dbo.sp_Persons_GetById;

IF EXISTS (SELECT * FROM sys.procedures WHERE schema_id = SCHEMA_ID('dbo') AND name = 'sp_Persons_GetAll') 
   AND NOT EXISTS (SELECT * FROM sys.procedures WHERE schema_id = SCHEMA_ID('assoc') AND name = 'sp_Persons_GetAll')
   ALTER SCHEMA assoc TRANSFER dbo.sp_Persons_GetAll;

IF EXISTS (SELECT * FROM sys.procedures WHERE schema_id = SCHEMA_ID('dbo') AND name = 'sp_Persons_Create') 
   AND NOT EXISTS (SELECT * FROM sys.procedures WHERE schema_id = SCHEMA_ID('assoc') AND name = 'sp_Persons_Create')
   ALTER SCHEMA assoc TRANSFER dbo.sp_Persons_Create;

IF EXISTS (SELECT * FROM sys.procedures WHERE schema_id = SCHEMA_ID('dbo') AND name = 'sp_Persons_Update') 
   AND NOT EXISTS (SELECT * FROM sys.procedures WHERE schema_id = SCHEMA_ID('assoc') AND name = 'sp_Persons_Update')
   ALTER SCHEMA assoc TRANSFER dbo.sp_Persons_Update;

IF EXISTS (SELECT * FROM sys.procedures WHERE schema_id = SCHEMA_ID('dbo') AND name = 'sp_Persons_Delete') 
   AND NOT EXISTS (SELECT * FROM sys.procedures WHERE schema_id = SCHEMA_ID('assoc') AND name = 'sp_Persons_Delete')
   ALTER SCHEMA assoc TRANSFER dbo.sp_Persons_Delete;


IF EXISTS (SELECT * FROM sys.procedures WHERE schema_id = SCHEMA_ID('dbo') AND name = 'sp_Occupancy_GetByAssetId') 
   AND NOT EXISTS (SELECT * FROM sys.procedures WHERE schema_id = SCHEMA_ID('assoc') AND name = 'sp_Occupancy_GetByAssetId')
   ALTER SCHEMA assoc TRANSFER dbo.sp_Occupancy_GetByAssetId;

IF EXISTS (SELECT * FROM sys.procedures WHERE schema_id = SCHEMA_ID('dbo') AND name = 'sp_Occupancy_Create') 
   AND NOT EXISTS (SELECT * FROM sys.procedures WHERE schema_id = SCHEMA_ID('assoc') AND name = 'sp_Occupancy_Create')
   ALTER SCHEMA assoc TRANSFER dbo.sp_Occupancy_Create;

IF EXISTS (SELECT * FROM sys.procedures WHERE schema_id = SCHEMA_ID('dbo') AND name = 'sp_Occupancy_Delete') 
   AND NOT EXISTS (SELECT * FROM sys.procedures WHERE schema_id = SCHEMA_ID('assoc') AND name = 'sp_Occupancy_Delete')
   ALTER SCHEMA assoc TRANSFER dbo.sp_Occupancy_Delete;

IF EXISTS (SELECT * FROM sys.procedures WHERE schema_id = SCHEMA_ID('dbo') AND name = 'sp_Occupancy_GetByUserId') 
   AND NOT EXISTS (SELECT * FROM sys.procedures WHERE schema_id = SCHEMA_ID('assoc') AND name = 'sp_Occupancy_GetByUserId')
   ALTER SCHEMA assoc TRANSFER dbo.sp_Occupancy_GetByUserId;


IF EXISTS (SELECT * FROM sys.procedures WHERE schema_id = SCHEMA_ID('dbo') AND name = 'sp_Vehicles_GetByAssetId') 
   AND NOT EXISTS (SELECT * FROM sys.procedures WHERE schema_id = SCHEMA_ID('assoc') AND name = 'sp_Vehicles_GetByAssetId')
   ALTER SCHEMA assoc TRANSFER dbo.sp_Vehicles_GetByAssetId;

IF EXISTS (SELECT * FROM sys.procedures WHERE schema_id = SCHEMA_ID('dbo') AND name = 'sp_Vehicles_Create') 
   AND NOT EXISTS (SELECT * FROM sys.procedures WHERE schema_id = SCHEMA_ID('assoc') AND name = 'sp_Vehicles_Create')
   ALTER SCHEMA assoc TRANSFER dbo.sp_Vehicles_Create;

IF EXISTS (SELECT * FROM sys.procedures WHERE schema_id = SCHEMA_ID('dbo') AND name = 'sp_Vehicles_Update') 
   AND NOT EXISTS (SELECT * FROM sys.procedures WHERE schema_id = SCHEMA_ID('assoc') AND name = 'sp_Vehicles_Update')
   ALTER SCHEMA assoc TRANSFER dbo.sp_Vehicles_Update;

IF EXISTS (SELECT * FROM sys.procedures WHERE schema_id = SCHEMA_ID('dbo') AND name = 'sp_Vehicles_Delete') 
   AND NOT EXISTS (SELECT * FROM sys.procedures WHERE schema_id = SCHEMA_ID('assoc') AND name = 'sp_Vehicles_Delete')
   ALTER SCHEMA assoc TRANSFER dbo.sp_Vehicles_Delete;


IF EXISTS (SELECT * FROM sys.procedures WHERE schema_id = SCHEMA_ID('dbo') AND name = 'sp_Pets_GetByAssetId') 
   AND NOT EXISTS (SELECT * FROM sys.procedures WHERE schema_id = SCHEMA_ID('assoc') AND name = 'sp_Pets_GetByAssetId')
   ALTER SCHEMA assoc TRANSFER dbo.sp_Pets_GetByAssetId;

IF EXISTS (SELECT * FROM sys.procedures WHERE schema_id = SCHEMA_ID('dbo') AND name = 'sp_Pets_Create') 
   AND NOT EXISTS (SELECT * FROM sys.procedures WHERE schema_id = SCHEMA_ID('assoc') AND name = 'sp_Pets_Create')
   ALTER SCHEMA assoc TRANSFER dbo.sp_Pets_Create;

IF EXISTS (SELECT * FROM sys.procedures WHERE schema_id = SCHEMA_ID('dbo') AND name = 'sp_Pets_Update') 
   AND NOT EXISTS (SELECT * FROM sys.procedures WHERE schema_id = SCHEMA_ID('assoc') AND name = 'sp_Pets_Update')
   ALTER SCHEMA assoc TRANSFER dbo.sp_Pets_Update;

IF EXISTS (SELECT * FROM sys.procedures WHERE schema_id = SCHEMA_ID('dbo') AND name = 'sp_Pets_Delete') 
   AND NOT EXISTS (SELECT * FROM sys.procedures WHERE schema_id = SCHEMA_ID('assoc') AND name = 'sp_Pets_Delete')
   ALTER SCHEMA assoc TRANSFER dbo.sp_Pets_Delete;


IF EXISTS (SELECT * FROM sys.procedures WHERE schema_id = SCHEMA_ID('dbo') AND name = 'sp_Invoices_GetById') 
   AND NOT EXISTS (SELECT * FROM sys.procedures WHERE schema_id = SCHEMA_ID('assoc') AND name = 'sp_Invoices_GetById')
   ALTER SCHEMA assoc TRANSFER dbo.sp_Invoices_GetById;

IF EXISTS (SELECT * FROM sys.procedures WHERE schema_id = SCHEMA_ID('dbo') AND name = 'sp_Invoices_GetAll') 
   AND NOT EXISTS (SELECT * FROM sys.procedures WHERE schema_id = SCHEMA_ID('assoc') AND name = 'sp_Invoices_GetAll')
   ALTER SCHEMA assoc TRANSFER dbo.sp_Invoices_GetAll;

IF EXISTS (SELECT * FROM sys.procedures WHERE schema_id = SCHEMA_ID('dbo') AND name = 'sp_Invoices_GetByAssetId') 
   AND NOT EXISTS (SELECT * FROM sys.procedures WHERE schema_id = SCHEMA_ID('assoc') AND name = 'sp_Invoices_GetByAssetId')
   ALTER SCHEMA assoc TRANSFER dbo.sp_Invoices_GetByAssetId;

IF EXISTS (SELECT * FROM sys.procedures WHERE schema_id = SCHEMA_ID('dbo') AND name = 'sp_Invoices_Create') 
   AND NOT EXISTS (SELECT * FROM sys.procedures WHERE schema_id = SCHEMA_ID('assoc') AND name = 'sp_Invoices_Create')
   ALTER SCHEMA assoc TRANSFER dbo.sp_Invoices_Create;

IF EXISTS (SELECT * FROM sys.procedures WHERE schema_id = SCHEMA_ID('dbo') AND name = 'sp_Invoices_UpdateStatus') 
   AND NOT EXISTS (SELECT * FROM sys.procedures WHERE schema_id = SCHEMA_ID('assoc') AND name = 'sp_Invoices_UpdateStatus')
   ALTER SCHEMA assoc TRANSFER dbo.sp_Invoices_UpdateStatus;

IF EXISTS (SELECT * FROM sys.procedures WHERE schema_id = SCHEMA_ID('dbo') AND name = 'sp_Invoices_Delete') 
   AND NOT EXISTS (SELECT * FROM sys.procedures WHERE schema_id = SCHEMA_ID('assoc') AND name = 'sp_Invoices_Delete')
   ALTER SCHEMA assoc TRANSFER dbo.sp_Invoices_Delete;


IF EXISTS (SELECT * FROM sys.procedures WHERE schema_id = SCHEMA_ID('dbo') AND name = 'sp_Payments_GetById') 
   AND NOT EXISTS (SELECT * FROM sys.procedures WHERE schema_id = SCHEMA_ID('assoc') AND name = 'sp_Payments_GetById')
   ALTER SCHEMA assoc TRANSFER dbo.sp_Payments_GetById;

IF EXISTS (SELECT * FROM sys.procedures WHERE schema_id = SCHEMA_ID('dbo') AND name = 'sp_Payments_GetByTenantId') 
   AND NOT EXISTS (SELECT * FROM sys.procedures WHERE schema_id = SCHEMA_ID('assoc') AND name = 'sp_Payments_GetByTenantId')
   ALTER SCHEMA assoc TRANSFER dbo.sp_Payments_GetByTenantId;

IF EXISTS (SELECT * FROM sys.procedures WHERE schema_id = SCHEMA_ID('dbo') AND name = 'sp_Payments_Create') 
   AND NOT EXISTS (SELECT * FROM sys.procedures WHERE schema_id = SCHEMA_ID('assoc') AND name = 'sp_Payments_Create')
   ALTER SCHEMA assoc TRANSFER dbo.sp_Payments_Create;

IF EXISTS (SELECT * FROM sys.procedures WHERE schema_id = SCHEMA_ID('dbo') AND name = 'sp_Payments_UpdateStatus') 
   AND NOT EXISTS (SELECT * FROM sys.procedures WHERE schema_id = SCHEMA_ID('assoc') AND name = 'sp_Payments_UpdateStatus')
   ALTER SCHEMA assoc TRANSFER dbo.sp_Payments_UpdateStatus;


IF EXISTS (SELECT * FROM sys.procedures WHERE schema_id = SCHEMA_ID('dbo') AND name = 'sp_Transactions_Create') 
   AND NOT EXISTS (SELECT * FROM sys.procedures WHERE schema_id = SCHEMA_ID('assoc') AND name = 'sp_Transactions_Create')
   ALTER SCHEMA assoc TRANSFER dbo.sp_Transactions_Create;

IF EXISTS (SELECT * FROM sys.procedures WHERE schema_id = SCHEMA_ID('dbo') AND name = 'sp_Transactions_GetByAssetId') 
   AND NOT EXISTS (SELECT * FROM sys.procedures WHERE schema_id = SCHEMA_ID('assoc') AND name = 'sp_Transactions_GetByAssetId')
   ALTER SCHEMA assoc TRANSFER dbo.sp_Transactions_GetByAssetId;

IF EXISTS (SELECT * FROM sys.procedures WHERE schema_id = SCHEMA_ID('dbo') AND name = 'sp_Transactions_GetByTenantId') 
   AND NOT EXISTS (SELECT * FROM sys.procedures WHERE schema_id = SCHEMA_ID('assoc') AND name = 'sp_Transactions_GetByTenantId')
   ALTER SCHEMA assoc TRANSFER dbo.sp_Transactions_GetByTenantId;

IF EXISTS (SELECT * FROM sys.procedures WHERE schema_id = SCHEMA_ID('dbo') AND name = 'sp_Transactions_GetBalanceByAssetId') 
   AND NOT EXISTS (SELECT * FROM sys.procedures WHERE schema_id = SCHEMA_ID('assoc') AND name = 'sp_Transactions_GetBalanceByAssetId')
   ALTER SCHEMA assoc TRANSFER dbo.sp_Transactions_GetBalanceByAssetId;


IF EXISTS (SELECT * FROM sys.procedures WHERE schema_id = SCHEMA_ID('dbo') AND name = 'sp_WorkOrders_GetById') 
   AND NOT EXISTS (SELECT * FROM sys.procedures WHERE schema_id = SCHEMA_ID('assoc') AND name = 'sp_WorkOrders_GetById')
   ALTER SCHEMA assoc TRANSFER dbo.sp_WorkOrders_GetById;

IF EXISTS (SELECT * FROM sys.procedures WHERE schema_id = SCHEMA_ID('dbo') AND name = 'sp_WorkOrders_GetAll') 
   AND NOT EXISTS (SELECT * FROM sys.procedures WHERE schema_id = SCHEMA_ID('assoc') AND name = 'sp_WorkOrders_GetAll')
   ALTER SCHEMA assoc TRANSFER dbo.sp_WorkOrders_GetAll;

IF EXISTS (SELECT * FROM sys.procedures WHERE schema_id = SCHEMA_ID('dbo') AND name = 'sp_WorkOrders_GetByAssetId') 
   AND NOT EXISTS (SELECT * FROM sys.procedures WHERE schema_id = SCHEMA_ID('assoc') AND name = 'sp_WorkOrders_GetByAssetId')
   ALTER SCHEMA assoc TRANSFER dbo.sp_WorkOrders_GetByAssetId;

IF EXISTS (SELECT * FROM sys.procedures WHERE schema_id = SCHEMA_ID('dbo') AND name = 'sp_WorkOrders_Create') 
   AND NOT EXISTS (SELECT * FROM sys.procedures WHERE schema_id = SCHEMA_ID('assoc') AND name = 'sp_WorkOrders_Create')
   ALTER SCHEMA assoc TRANSFER dbo.sp_WorkOrders_Create;

IF EXISTS (SELECT * FROM sys.procedures WHERE schema_id = SCHEMA_ID('dbo') AND name = 'sp_WorkOrders_Update') 
   AND NOT EXISTS (SELECT * FROM sys.procedures WHERE schema_id = SCHEMA_ID('assoc') AND name = 'sp_WorkOrders_Update')
   ALTER SCHEMA assoc TRANSFER dbo.sp_WorkOrders_Update;

IF EXISTS (SELECT * FROM sys.procedures WHERE schema_id = SCHEMA_ID('dbo') AND name = 'sp_WorkOrders_UpdateStatus') 
   AND NOT EXISTS (SELECT * FROM sys.procedures WHERE schema_id = SCHEMA_ID('assoc') AND name = 'sp_WorkOrders_UpdateStatus')
   ALTER SCHEMA assoc TRANSFER dbo.sp_WorkOrders_UpdateStatus;

IF EXISTS (SELECT * FROM sys.procedures WHERE schema_id = SCHEMA_ID('dbo') AND name = 'sp_WorkOrders_Delete') 
   AND NOT EXISTS (SELECT * FROM sys.procedures WHERE schema_id = SCHEMA_ID('assoc') AND name = 'sp_WorkOrders_Delete')
   ALTER SCHEMA assoc TRANSFER dbo.sp_WorkOrders_Delete;


IF EXISTS (SELECT * FROM sys.procedures WHERE schema_id = SCHEMA_ID('dbo') AND name = 'sp_Broadcasts_GetById') 
   AND NOT EXISTS (SELECT * FROM sys.procedures WHERE schema_id = SCHEMA_ID('assoc') AND name = 'sp_Broadcasts_GetById')
   ALTER SCHEMA assoc TRANSFER dbo.sp_Broadcasts_GetById;

IF EXISTS (SELECT * FROM sys.procedures WHERE schema_id = SCHEMA_ID('dbo') AND name = 'sp_Broadcasts_GetAll') 
   AND NOT EXISTS (SELECT * FROM sys.procedures WHERE schema_id = SCHEMA_ID('assoc') AND name = 'sp_Broadcasts_GetAll')
   ALTER SCHEMA assoc TRANSFER dbo.sp_Broadcasts_GetAll;

IF EXISTS (SELECT * FROM sys.procedures WHERE schema_id = SCHEMA_ID('dbo') AND name = 'sp_Broadcasts_GetByAssetId') 
   AND NOT EXISTS (SELECT * FROM sys.procedures WHERE schema_id = SCHEMA_ID('assoc') AND name = 'sp_Broadcasts_GetByAssetId')
   ALTER SCHEMA assoc TRANSFER dbo.sp_Broadcasts_GetByAssetId;

IF EXISTS (SELECT * FROM sys.procedures WHERE schema_id = SCHEMA_ID('dbo') AND name = 'sp_Broadcasts_Create') 
   AND NOT EXISTS (SELECT * FROM sys.procedures WHERE schema_id = SCHEMA_ID('assoc') AND name = 'sp_Broadcasts_Create')
   ALTER SCHEMA assoc TRANSFER dbo.sp_Broadcasts_Create;

IF EXISTS (SELECT * FROM sys.procedures WHERE schema_id = SCHEMA_ID('dbo') AND name = 'sp_Broadcasts_Delete') 
   AND NOT EXISTS (SELECT * FROM sys.procedures WHERE schema_id = SCHEMA_ID('assoc') AND name = 'sp_Broadcasts_Delete')
   ALTER SCHEMA assoc TRANSFER dbo.sp_Broadcasts_Delete;


IF EXISTS (SELECT * FROM sys.procedures WHERE schema_id = SCHEMA_ID('dbo') AND name = 'sp_TariffGroups_GetByTenantId') 
   AND NOT EXISTS (SELECT * FROM sys.procedures WHERE schema_id = SCHEMA_ID('assoc') AND name = 'sp_TariffGroups_GetByTenantId')
   ALTER SCHEMA assoc TRANSFER dbo.sp_TariffGroups_GetByTenantId;

IF EXISTS (SELECT * FROM sys.procedures WHERE schema_id = SCHEMA_ID('dbo') AND name = 'sp_TariffGroups_Create') 
   AND NOT EXISTS (SELECT * FROM sys.procedures WHERE schema_id = SCHEMA_ID('assoc') AND name = 'sp_TariffGroups_Create')
   ALTER SCHEMA assoc TRANSFER dbo.sp_TariffGroups_Create;

IF EXISTS (SELECT * FROM sys.procedures WHERE schema_id = SCHEMA_ID('dbo') AND name = 'sp_TariffGroups_Update') 
   AND NOT EXISTS (SELECT * FROM sys.procedures WHERE schema_id = SCHEMA_ID('assoc') AND name = 'sp_TariffGroups_Update')
   ALTER SCHEMA assoc TRANSFER dbo.sp_TariffGroups_Update;

IF EXISTS (SELECT * FROM sys.procedures WHERE schema_id = SCHEMA_ID('dbo') AND name = 'sp_TariffGroups_Delete') 
   AND NOT EXISTS (SELECT * FROM sys.procedures WHERE schema_id = SCHEMA_ID('assoc') AND name = 'sp_TariffGroups_Delete')
   ALTER SCHEMA assoc TRANSFER dbo.sp_TariffGroups_Delete;


IF EXISTS (SELECT * FROM sys.procedures WHERE schema_id = SCHEMA_ID('dbo') AND name = 'sp_TariffLayers_GetByGroupId') 
   AND NOT EXISTS (SELECT * FROM sys.procedures WHERE schema_id = SCHEMA_ID('assoc') AND name = 'sp_TariffLayers_GetByGroupId')
   ALTER SCHEMA assoc TRANSFER dbo.sp_TariffLayers_GetByGroupId;

IF EXISTS (SELECT * FROM sys.procedures WHERE schema_id = SCHEMA_ID('dbo') AND name = 'sp_TariffLayers_Create') 
   AND NOT EXISTS (SELECT * FROM sys.procedures WHERE schema_id = SCHEMA_ID('assoc') AND name = 'sp_TariffLayers_Create')
   ALTER SCHEMA assoc TRANSFER dbo.sp_TariffLayers_Create;

IF EXISTS (SELECT * FROM sys.procedures WHERE schema_id = SCHEMA_ID('dbo') AND name = 'sp_TariffLayers_Update') 
   AND NOT EXISTS (SELECT * FROM sys.procedures WHERE schema_id = SCHEMA_ID('assoc') AND name = 'sp_TariffLayers_Update')
   ALTER SCHEMA assoc TRANSFER dbo.sp_TariffLayers_Update;

IF EXISTS (SELECT * FROM sys.procedures WHERE schema_id = SCHEMA_ID('dbo') AND name = 'sp_TariffLayers_Delete') 
   AND NOT EXISTS (SELECT * FROM sys.procedures WHERE schema_id = SCHEMA_ID('assoc') AND name = 'sp_TariffLayers_Delete')
   ALTER SCHEMA assoc TRANSFER dbo.sp_TariffLayers_Delete;


IF EXISTS (SELECT * FROM sys.procedures WHERE schema_id = SCHEMA_ID('dbo') AND name = 'sp_AssetTariffs_GetByAssetId') 
   AND NOT EXISTS (SELECT * FROM sys.procedures WHERE schema_id = SCHEMA_ID('assoc') AND name = 'sp_AssetTariffs_GetByAssetId')
   ALTER SCHEMA assoc TRANSFER dbo.sp_AssetTariffs_GetByAssetId;

IF EXISTS (SELECT * FROM sys.procedures WHERE schema_id = SCHEMA_ID('dbo') AND name = 'sp_AssetTariffs_Upsert') 
   AND NOT EXISTS (SELECT * FROM sys.procedures WHERE schema_id = SCHEMA_ID('assoc') AND name = 'sp_AssetTariffs_Upsert')
   ALTER SCHEMA assoc TRANSFER dbo.sp_AssetTariffs_Upsert;

IF EXISTS (SELECT * FROM sys.procedures WHERE schema_id = SCHEMA_ID('dbo') AND name = 'sp_AssetTariffs_Delete') 
   AND NOT EXISTS (SELECT * FROM sys.procedures WHERE schema_id = SCHEMA_ID('assoc') AND name = 'sp_AssetTariffs_Delete')
   ALTER SCHEMA assoc TRANSFER dbo.sp_AssetTariffs_Delete;

IF EXISTS (SELECT * FROM sys.procedures WHERE schema_id = SCHEMA_ID('dbo') AND name = 'sp_AssetTariffs_GetActiveByTenantId') 
   AND NOT EXISTS (SELECT * FROM sys.procedures WHERE schema_id = SCHEMA_ID('assoc') AND name = 'sp_AssetTariffs_GetActiveByTenantId')
   ALTER SCHEMA assoc TRANSFER dbo.sp_AssetTariffs_GetActiveByTenantId;
GO
GO
GO
