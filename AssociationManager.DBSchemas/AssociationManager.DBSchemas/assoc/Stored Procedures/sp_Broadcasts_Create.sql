CREATE   PROCEDURE assoc.sp_Broadcasts_Create @TenantId INT, @AssociationId INT, @Title NVARCHAR(200), @Content NVARCHAR(MAX), @Category NVARCHAR(50), @CreatedDate DATETIME, @CreatedBy INT, @IsPinned BIT, @ExpiresDate DATETIME = NULL, @AssetId INT = NULL AS 
BEGIN 
    INSERT INTO assoc.Broadcasts (TenantId, AssociationId, Title, Content, Category, CreatedDate, CreatedBy, IsPinned, ExpiresDate, AssetId) 
    VALUES (@TenantId, @AssociationId, @Title, @Content, @Category, @CreatedDate, @CreatedBy, @IsPinned, @ExpiresDate, @AssetId); 

    SELECT SCOPE_IDENTITY();
END