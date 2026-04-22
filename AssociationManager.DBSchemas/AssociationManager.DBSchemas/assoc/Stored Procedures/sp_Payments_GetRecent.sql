
-- 3.2 sp_Payments_GetRecent
CREATE   PROCEDURE assoc.sp_Payments_GetRecent
    @TenantId INT,
    @AssociationId INT,
    @Count INT,
    @AssetIds NVARCHAR(MAX) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SELECT TOP (@Count) * 
    FROM assoc.Payments 
    WHERE TenantId = @TenantId 
    AND AssociationId = @AssociationId 
    AND (@AssetIds IS NULL OR AssetId IN (SELECT CAST(value AS INT) FROM STRING_SPLIT(@AssetIds, ',')))
    ORDER BY CreatedDate DESC
END