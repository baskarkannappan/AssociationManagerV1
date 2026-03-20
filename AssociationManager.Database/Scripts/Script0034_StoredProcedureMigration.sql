-- Corporate Procedures
ALTER SCHEMA corp TRANSFER dbo.sp_Tenants_GetById;
ALTER SCHEMA corp TRANSFER dbo.sp_Tenants_GetAll;
ALTER SCHEMA corp TRANSFER dbo.sp_Tenants_Create;
ALTER SCHEMA corp TRANSFER dbo.sp_Tenants_Update;

ALTER SCHEMA corp TRANSFER dbo.sp_Associations_GetById;
ALTER SCHEMA corp TRANSFER dbo.sp_Associations_GetAll;
ALTER SCHEMA corp TRANSFER dbo.sp_Associations_GetAllByTenantId;
ALTER SCHEMA corp TRANSFER dbo.sp_Associations_Create;
ALTER SCHEMA corp TRANSFER dbo.sp_Associations_Update;
ALTER SCHEMA corp TRANSFER dbo.sp_Associations_Delete;
ALTER SCHEMA corp TRANSFER dbo.sp_Associations_GetByUserId;

ALTER SCHEMA corp TRANSFER dbo.sp_Subscriptions_GetByAssociationId;
ALTER SCHEMA corp TRANSFER dbo.sp_Subscriptions_Upsert;
ALTER SCHEMA corp TRANSFER dbo.sp_SubscriptionPlans_GetAll;
ALTER SCHEMA corp TRANSFER dbo.sp_SubscriptionPlans_Upsert;

ALTER SCHEMA corp TRANSFER dbo.sp_Users_GetById;
ALTER SCHEMA corp TRANSFER dbo.sp_Users_GetByGoogleId;
ALTER SCHEMA corp TRANSFER dbo.sp_Users_GetByEmail;
ALTER SCHEMA corp TRANSFER dbo.sp_Users_GetByTenantId;
ALTER SCHEMA corp TRANSFER dbo.sp_Users_Create;
ALTER SCHEMA corp TRANSFER dbo.sp_Users_Update;

ALTER SCHEMA corp TRANSFER dbo.sp_UserAssociations_CheckExists;
ALTER SCHEMA corp TRANSFER dbo.sp_UserAssociations_Upsert;
ALTER SCHEMA corp TRANSFER dbo.sp_UserAssociations_GetRole;
ALTER SCHEMA corp TRANSFER dbo.sp_UserAssociations_Delete;

ALTER SCHEMA corp TRANSFER dbo.sp_AuditLogs_Create;
ALTER SCHEMA corp TRANSFER dbo.sp_AuditLogs_GetByTenantId;
ALTER SCHEMA corp TRANSFER dbo.sp_RefreshTokens_GetByToken;
ALTER SCHEMA corp TRANSFER dbo.sp_RefreshTokens_Upsert;
ALTER SCHEMA corp TRANSFER dbo.sp_RefreshTokens_Delete;

-- Association Procedures
ALTER SCHEMA assoc TRANSFER dbo.sp_Assets_GetById;
ALTER SCHEMA assoc TRANSFER dbo.sp_Assets_GetAll;
ALTER SCHEMA assoc TRANSFER dbo.sp_Assets_Create;
ALTER SCHEMA assoc TRANSFER dbo.sp_Assets_Update;
ALTER SCHEMA assoc TRANSFER dbo.sp_Assets_Delete;
ALTER SCHEMA assoc TRANSFER dbo.sp_Assets_GetTree;

ALTER SCHEMA assoc TRANSFER dbo.sp_Persons_GetById;
ALTER SCHEMA assoc TRANSFER dbo.sp_Persons_GetAll;
ALTER SCHEMA assoc TRANSFER dbo.sp_Persons_Create;
ALTER SCHEMA assoc TRANSFER dbo.sp_Persons_Update;
ALTER SCHEMA assoc TRANSFER dbo.sp_Persons_Delete;

ALTER SCHEMA assoc TRANSFER dbo.sp_Occupancy_GetByAssetId;
ALTER SCHEMA assoc TRANSFER dbo.sp_Occupancy_Create;
ALTER SCHEMA assoc TRANSFER dbo.sp_Occupancy_Delete;
ALTER SCHEMA assoc TRANSFER dbo.sp_Occupancy_GetByUserId;

ALTER SCHEMA assoc TRANSFER dbo.sp_Vehicles_GetByAssetId;
ALTER SCHEMA assoc TRANSFER dbo.sp_Vehicles_Create;
ALTER SCHEMA assoc TRANSFER dbo.sp_Vehicles_Update;
ALTER SCHEMA assoc TRANSFER dbo.sp_Vehicles_Delete;

ALTER SCHEMA assoc TRANSFER dbo.sp_Pets_GetByAssetId;
ALTER SCHEMA assoc TRANSFER dbo.sp_Pets_Create;
ALTER SCHEMA assoc TRANSFER dbo.sp_Pets_Update;
ALTER SCHEMA assoc TRANSFER dbo.sp_Pets_Delete;

ALTER SCHEMA assoc TRANSFER dbo.sp_Invoices_GetById;
ALTER SCHEMA assoc TRANSFER dbo.sp_Invoices_GetAll;
ALTER SCHEMA assoc TRANSFER dbo.sp_Invoices_GetByAssetId;
ALTER SCHEMA assoc TRANSFER dbo.sp_Invoices_Create;
ALTER SCHEMA assoc TRANSFER dbo.sp_Invoices_UpdateStatus;
ALTER SCHEMA assoc TRANSFER dbo.sp_Invoices_Delete;

ALTER SCHEMA assoc TRANSFER dbo.sp_Payments_GetById;
ALTER SCHEMA assoc TRANSFER dbo.sp_Payments_GetByTenantId;
ALTER SCHEMA assoc TRANSFER dbo.sp_Payments_Create;
ALTER SCHEMA assoc TRANSFER dbo.sp_Payments_UpdateStatus;

ALTER SCHEMA assoc TRANSFER dbo.sp_Transactions_Create;
ALTER SCHEMA assoc TRANSFER dbo.sp_Transactions_GetByAssetId;
ALTER SCHEMA assoc TRANSFER dbo.sp_Transactions_GetByTenantId;
ALTER SCHEMA assoc TRANSFER dbo.sp_Transactions_GetBalanceByAssetId;

ALTER SCHEMA assoc TRANSFER dbo.sp_WorkOrders_GetById;
ALTER SCHEMA assoc TRANSFER dbo.sp_WorkOrders_GetAll;
ALTER SCHEMA assoc TRANSFER dbo.sp_WorkOrders_GetByAssetId;
ALTER SCHEMA assoc TRANSFER dbo.sp_WorkOrders_Create;
ALTER SCHEMA assoc TRANSFER dbo.sp_WorkOrders_Update;
ALTER SCHEMA assoc TRANSFER dbo.sp_WorkOrders_UpdateStatus;
ALTER SCHEMA assoc TRANSFER dbo.sp_WorkOrders_Delete;

ALTER SCHEMA assoc TRANSFER dbo.sp_Broadcasts_GetById;
ALTER SCHEMA assoc TRANSFER dbo.sp_Broadcasts_GetAll;
ALTER SCHEMA assoc TRANSFER dbo.sp_Broadcasts_GetByAssetId;
ALTER SCHEMA assoc TRANSFER dbo.sp_Broadcasts_Create;
ALTER SCHEMA assoc TRANSFER dbo.sp_Broadcasts_Delete;

ALTER SCHEMA assoc TRANSFER dbo.sp_TariffGroups_GetByTenantId;
ALTER SCHEMA assoc TRANSFER dbo.sp_TariffGroups_Create;
ALTER SCHEMA assoc TRANSFER dbo.sp_TariffGroups_Update;
ALTER SCHEMA assoc TRANSFER dbo.sp_TariffGroups_Delete;

ALTER SCHEMA assoc TRANSFER dbo.sp_TariffLayers_GetByGroupId;
ALTER SCHEMA assoc TRANSFER dbo.sp_TariffLayers_Create;
ALTER SCHEMA assoc TRANSFER dbo.sp_TariffLayers_Update;
ALTER SCHEMA assoc TRANSFER dbo.sp_TariffLayers_Delete;

ALTER SCHEMA assoc TRANSFER dbo.sp_AssetTariffs_GetByAssetId;
ALTER SCHEMA assoc TRANSFER dbo.sp_AssetTariffs_Upsert;
ALTER SCHEMA assoc TRANSFER dbo.sp_AssetTariffs_Delete;
ALTER SCHEMA assoc TRANSFER dbo.sp_AssetTariffs_GetActiveByTenantId;
GO
