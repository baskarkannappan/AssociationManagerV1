-- MIGRATION SCRIPT: Move Association 4029 to its own Tenant (Option B) - FINAL REFINEMENT
-- This logic implements the new multi-tenant architecture for existing test data.

BEGIN TRANSACTION;

BEGIN TRY
    -- 1. Create a brand new Tenant for this association
    DECLARE @NewTenantId INT;
    INSERT INTO corp.Tenants (Name, CreatedDate, IsActive)
    VALUES ('VILLA Villa 1 - Standalone', GETUTCDATE(), 1);
    SET @NewTenantId = SCOPE_IDENTITY();

    PRINT 'New Tenant Created with ID: ' + CAST(@NewTenantId AS VARCHAR);

    -- 2. Update the Association record (This is the primary link)
    UPDATE corp.Associations 
    SET TenantId = @NewTenantId 
    WHERE AssociationId = 4029;

    -- 3. Update all linked operational records in the assoc schema that HAVE a TenantId column
    -- These tables use TenantId for hard partitioning/isolation.
    
    UPDATE assoc.Assets SET TenantId = @NewTenantId WHERE AssociationId = 4029;
    UPDATE assoc.Occupancy SET TenantId = @NewTenantId WHERE AssociationId = 4029;
    UPDATE assoc.Invoices SET TenantId = @NewTenantId WHERE AssociationId = 4029;
    UPDATE assoc.Payments SET TenantId = @NewTenantId WHERE AssociationId = 4029;
    UPDATE assoc.Transactions SET TenantId = @NewTenantId WHERE AssociationId = 4029;
    UPDATE assoc.TariffGroups SET TenantId = @NewTenantId WHERE AssociationId = 4029;
    UPDATE assoc.BillingBatches SET TenantId = @NewTenantId WHERE AssociationId = 4029;

    -- 4. Map the Global User (UserId 1) to the new Tenant in the corp schema
    -- The table name is corp.UserAssociations (discovered from DBSchemas)
    
    IF NOT EXISTS (SELECT 1 FROM corp.UserAssociations WHERE UserId = 1 AND TenantId = @NewTenantId)
    BEGIN
        EXEC corp.sp_UserAssociations_Upsert @UserId = 1, @TenantId = @NewTenantId, @Role = 'AssociationAdmin';
    END

    COMMIT TRANSACTION;
    PRINT 'Migration successful. Association 4029 is now Standalone in Tenant ' + CAST(@NewTenantId AS VARCHAR);

END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
    PRINT 'Migration failed: ' + ERROR_MESSAGE();
END CATCH;
GO
