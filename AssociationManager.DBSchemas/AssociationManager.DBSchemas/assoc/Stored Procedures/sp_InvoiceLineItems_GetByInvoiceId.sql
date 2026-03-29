CREATE   PROCEDURE assoc.sp_InvoiceLineItems_GetByInvoiceId 
    @InvoiceId INT 
AS 
BEGIN 
    SELECT * FROM assoc.InvoiceLineItems WHERE InvoiceId = @InvoiceId; 
END