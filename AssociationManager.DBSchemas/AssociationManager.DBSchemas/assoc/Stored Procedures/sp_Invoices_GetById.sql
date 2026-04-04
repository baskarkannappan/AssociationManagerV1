CREATE   PROCEDURE assoc.sp_Invoices_GetById
    @Id INT,
    @TenantId INT,
    @AssociationId INT
AS
BEGIN
    SELECT i.*, a.Name as AssetName
    FROM assoc.Invoices i
    LEFT JOIN assoc.Assets a ON i.AssetId = a.AssetId
    WHERE i.InvoiceId = @Id 
      AND i.TenantId = @TenantId 
      AND (@AssociationId IS NULL OR i.AssociationId = @AssociationId);
END