CREATE PROCEDURE assoc.sp_InvoiceLineItems_GetBulk
    @InvoiceIds NVARCHAR(MAX)
AS
BEGIN
    SET NOCOUNT ON;
    
    SELECT 
        li.*
    FROM assoc.InvoiceLineItems li
    INNER JOIN STRING_SPLIT(@InvoiceIds, ',') s ON li.InvoiceId = CAST(s.value AS INT);
END
