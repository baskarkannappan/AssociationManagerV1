CREATE PROCEDURE corp.sp_PlatformInvoices_UpdateStatus
    @PlatformInvoiceId INT,
    @Status NVARCHAR(50)
AS
BEGIN
    UPDATE corp.PlatformInvoices
    SET Status = @Status
    WHERE PlatformInvoiceId = @PlatformInvoiceId;
END