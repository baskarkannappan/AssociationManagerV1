CREATE   PROCEDURE assoc.sp_BillingBatches_GetByAssociation 
    @AssociationId INT, 
    @TenantId INT 
AS 
BEGIN 
    SELECT * FROM assoc.BillingBatches WHERE AssociationId = @AssociationId AND TenantId = @TenantId ORDER BY CreatedDate DESC; 
END