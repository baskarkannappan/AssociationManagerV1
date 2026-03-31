-- Stored Procedures

-- Get Bank Details
CREATE   PROCEDURE assoc.sp_AssociationBankDetails_Get
    @AssociationId INT,
    @TenantId INT
AS
BEGIN
    SELECT * FROM assoc.AssociationBankDetails 
    WHERE AssociationId = @AssociationId AND TenantId = @TenantId;
END;