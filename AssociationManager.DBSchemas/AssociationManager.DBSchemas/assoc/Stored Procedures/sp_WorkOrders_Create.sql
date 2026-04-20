CREATE PROCEDURE assoc.sp_WorkOrders_Create 
    @TenantId INT, 
    @AssociationId INT, 
    @AssetId INT = NULL, 
    @Title NVARCHAR(200), 
    @Description NVARCHAR(MAX) = NULL, 
    @Priority NVARCHAR(50), 
    @Status NVARCHAR(50), 
    @CreatedDate DATETIME, 
    @CreatedBy INT 
AS 
BEGIN 
    INSERT INTO assoc.WorkOrders (TenantId, AssociationId, AssetId, Title, Description, Priority, Status, CreatedDate, CreatedBy) 
    VALUES (@TenantId, @AssociationId, @AssetId, @Title, @Description, @Priority, @Status, @CreatedDate, @CreatedBy); 
    SELECT SCOPE_IDENTITY(); 
END