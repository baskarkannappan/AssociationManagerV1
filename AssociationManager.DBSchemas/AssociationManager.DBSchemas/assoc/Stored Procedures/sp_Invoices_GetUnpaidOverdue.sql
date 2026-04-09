-- assoc.sp_Invoices_GetUnpaidOverdue.sql
IF EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[assoc].[sp_Invoices_GetUnpaidOverdue]') AND type in (N'P', N'PC'))
    DROP PROCEDURE [assoc].[sp_Invoices_GetUnpaidOverdue];
GO

CREATE PROCEDURE assoc.sp_Invoices_GetUnpaidOverdue
AS
BEGIN
    SET NOCOUNT ON;

    -- Fetches all unpaid invoices past their due date across all tenants and associations
    -- This is intended for cross-tenant background automation
    SELECT 
        InvoiceId,
        TenantId,
        AssociationId,
        AssetId,
        Title,
        [Description],
        Amount,
        DueDate,
        [Status],
        CreatedDate,
        IsAdvancePaid
    FROM assoc.Invoices
    WHERE [Status] NOT IN ('Paid', 'Cancelled', 'Void', 'Draft')
    AND DueDate < GETUTCDATE();
END
GO
