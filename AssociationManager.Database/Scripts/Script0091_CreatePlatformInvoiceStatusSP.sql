-- Script0091_CreatePlatformInvoiceStatusSP.sql
-- Create stored procedure to update platform invoice status

IF EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID('corp.sp_PlatformInvoices_UpdateStatus') AND type = 'P')
BEGIN
    DROP PROCEDURE corp.sp_PlatformInvoices_UpdateStatus
END
GO

CREATE PROCEDURE corp.sp_PlatformInvoices_UpdateStatus
    @PlatformInvoiceId INT,
    @Status NVARCHAR(50)
AS
BEGIN
    UPDATE corp.PlatformInvoices
    SET Status = @Status
    WHERE PlatformInvoiceId = @PlatformInvoiceId;
END
GO
