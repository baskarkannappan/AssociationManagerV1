CREATE   PROCEDURE corp.sp_Association_BulkDelete
    @AssociationId INT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    DECLARE @TenantId INT;
    SELECT @TenantId = TenantId FROM corp.Associations WHERE AssociationId = @AssociationId;

    BEGIN TRANSACTION;

    BEGIN TRY
        -- 1. Tier 0: Global Audit Logs & Child Transactions
        DELETE FROM corp.AuditLogs WHERE AssociationId = @AssociationId;
        DELETE FROM assoc.PaymentTransactions WHERE AssociationId = @AssociationId;
        DELETE FROM assoc.PaymentOrders WHERE AssociationId = @AssociationId;
        
        -- 2. Tier 2: Ledgers & Invoices
        DELETE FROM assoc.Transactions WHERE AssociationId = @AssociationId;
        DELETE FROM assoc.Payments WHERE AssociationId = @AssociationId;
        DELETE FROM assoc.InvoiceLineItems WHERE InvoiceId IN (SELECT InvoiceId FROM assoc.Invoices WHERE AssociationId = @AssociationId);
        DELETE FROM assoc.Invoices WHERE AssociationId = @AssociationId;
        DELETE FROM assoc.BillingBatches WHERE AssociationId = @AssociationId;

        -- 3. Tier 3: Asset Details
        DELETE FROM assoc.Vehicles WHERE AssetId IN (SELECT AssetId FROM assoc.Assets WHERE AssociationId = @AssociationId);
        DELETE FROM assoc.Pets WHERE AssetId IN (SELECT AssetId FROM assoc.Assets WHERE AssociationId = @AssociationId);
        DELETE FROM assoc.Occupancy WHERE AssetId IN (SELECT AssetId FROM assoc.Assets WHERE AssociationId = @AssociationId);
        DELETE FROM assoc.Persons WHERE AssociationId = @AssociationId;

        -- 4. Tier 4: Core Registry
        DELETE FROM assoc.AssetTariffs WHERE AssetId IN (SELECT AssetId FROM assoc.Assets WHERE AssociationId = @AssociationId);
        DELETE FROM assoc.TariffLayers WHERE TariffGroupId IN (SELECT TariffGroupId FROM assoc.TariffGroups WHERE AssociationId = @AssociationId);
        DELETE FROM assoc.TariffGroups WHERE AssociationId = @AssociationId;
        DELETE FROM assoc.Assets WHERE AssociationId = @AssociationId;

        -- 5. Tier 5: Governance & Workflow
        DELETE FROM assoc.Votes WHERE ElectionId IN (SELECT ElectionId FROM assoc.Elections WHERE AssociationId = @AssociationId);
        DELETE FROM assoc.Candidates WHERE ElectionId IN (SELECT ElectionId FROM assoc.Elections WHERE AssociationId = @AssociationId);
        DELETE FROM assoc.Elections WHERE AssociationId = @AssociationId;
        
        DELETE FROM assoc.MeetingMinutes WHERE MeetingId IN (SELECT MeetingId FROM assoc.Meetings WHERE AssociationId = @AssociationId);
        DELETE FROM assoc.Meetings WHERE AssociationId = @AssociationId;
        
        DELETE FROM assoc.CommitteeMembers WHERE AssociationId = @AssociationId;
        DELETE FROM assoc.WorkOrders WHERE AssociationId = @AssociationId;
        DELETE FROM assoc.Broadcasts WHERE AssociationId = @AssociationId;

        -- 6. Tier 6: Profiles
        DELETE FROM assoc.ByeLaws WHERE AssociationId = @AssociationId;
        DELETE FROM assoc.AssociationBankDetails WHERE AssociationId = @AssociationId;
        DELETE FROM assoc.AssociationProfile WHERE AssociationId = @AssociationId;

        -- 7. Tier 7: Corporate Integration
        DELETE FROM corp.PlatformPayments WHERE PlatformInvoiceId IN (SELECT PlatformInvoiceId FROM corp.PlatformInvoices WHERE AssociationId = @AssociationId);
        DELETE FROM corp.PlatformInvoices WHERE AssociationId = @AssociationId;
        DELETE FROM corp.AssociationSubscriptions WHERE AssociationId = @AssociationId;

        -- 8. Tier 8: Identity & Mapping
        -- Delete RefreshTokens for any system (corp or assoc schema) linked to users of this association
        DELETE FROM corp.RefreshTokens WHERE UserId IN (SELECT UserId FROM corp.Users WHERE AssociationId = @AssociationId);
        
        IF EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[assoc].[RefreshTokens]') AND type in (N'U'))
        BEGIN
            DELETE FROM assoc.RefreshTokens WHERE UserId IN (SELECT UserId FROM corp.Users WHERE AssociationId = @AssociationId);
        END

        -- Handle User Mappings across schemas
        IF @TenantId IS NOT NULL
        BEGIN
            DELETE FROM corp.UserAssociations WHERE TenantId = @TenantId;
            DELETE FROM corp.TenantPaymentConfig WHERE TenantId = @TenantId;
        END

        IF EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[assoc].[UserAssociations]') AND type in (N'U'))
        BEGIN
            DELETE FROM assoc.UserAssociations WHERE AssociationId = @AssociationId;
        END
        
        -- Delete association-specific users only if they are not mapped to any other associations
        DELETE FROM corp.Users 
        WHERE AssociationId = @AssociationId
        AND UserId NOT IN (SELECT UserId FROM corp.UserAssociations WHERE AssociationId != @AssociationId);

        -- 9. Tier 9: Final Primary Deletion
        DELETE FROM corp.Associations WHERE AssociationId = @AssociationId;

        -- Optional: Delete Tenant record if it is now empty and not used elsewhere
        -- IF @TenantId IS NOT NULL AND NOT EXISTS (SELECT 1 FROM corp.Associations WHERE TenantId = @TenantId)
        -- BEGIN
        --     DELETE FROM corp.Tenants WHERE TenantId = @TenantId;
        -- END

        COMMIT TRANSACTION;
        PRINT 'Bulk delete successful for AssociationId: ' + CAST(@AssociationId AS VARCHAR(10));
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        
        DECLARE @ErrorMessage NVARCHAR(4000) = ERROR_MESSAGE();
        DECLARE @ErrorSeverity INT = ERROR_SEVERITY();
        DECLARE @ErrorState INT = ERROR_STATE();
        
        RAISERROR (@ErrorMessage, @ErrorSeverity, @ErrorState);
    END CATCH
END;