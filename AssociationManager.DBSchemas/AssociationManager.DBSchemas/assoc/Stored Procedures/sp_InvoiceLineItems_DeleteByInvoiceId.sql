CREATE PROCEDURE assoc.sp_InvoiceLineItems_DeleteByInvoiceId
    @InvoiceId INT
AS
BEGIN
    SET NOCOUNT ON;
    DELETE FROM assoc.InvoiceLineItems WHERE InvoiceId = @InvoiceId;
END
GO
