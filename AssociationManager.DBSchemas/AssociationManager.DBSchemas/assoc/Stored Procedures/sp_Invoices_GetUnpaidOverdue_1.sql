CREATE PROCEDURE assoc.sp_Invoices_GetUnpaidOverdue
AS
BEGIN
    SET NOCOUNT ON;
    SELECT 
        InvoiceId, TenantId, AssociationId, AssetId, Title, [Description], Amount, DueDate, [Status], CreatedDate, IsAdvancePaid
    FROM assoc.Invoices
    WHERE [Status] NOT IN ('Paid', 'Cancelled', 'Void', 'Draft')
    AND DueDate < GETUTCDATE();
END;