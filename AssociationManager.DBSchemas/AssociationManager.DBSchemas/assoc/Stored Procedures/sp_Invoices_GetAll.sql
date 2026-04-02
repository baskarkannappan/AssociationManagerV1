-- 4. Update GetAll
CREATE   PROCEDURE assoc.sp_Invoices_GetAll
    @TenantId INT,
    @AssociationId INT
AS
BEGIN
    SELECT i.*, 
           a.Name AS AssetName,
           CASE WHEN EXISTS (SELECT 1 FROM assoc.Payments p WHERE p.InvoiceId = i.InvoiceId AND p.Notes LIKE '%Advance%') THEN 1 ELSE 0 END AS IsAdvancePaid
    FROM assoc.Invoices i
    LEFT JOIN assoc.Assets a ON i.AssetId = a.AssetId
    WHERE i.TenantId = @TenantId AND i.AssociationId = @AssociationId
    ORDER BY i.CreatedDate DESC;
END;