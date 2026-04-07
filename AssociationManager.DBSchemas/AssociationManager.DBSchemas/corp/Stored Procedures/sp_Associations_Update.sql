CREATE   PROCEDURE corp.sp_Associations_Update 
    @AssociationId INT, 
    @TenantId INT, 
    @Name NVARCHAR(255), 
    @Description NVARCHAR(MAX),
    @PlatformAccountId INT = NULL,
    @AdminPaysFee BIT = 1
AS 
BEGIN 
    UPDATE corp.Associations 
    SET Name = @Name, 
        Description = @Description,
        PlatformAccountId = @PlatformAccountId,
        AdminPaysFee = @AdminPaysFee
    WHERE AssociationId = @AssociationId AND TenantId = @TenantId; 
END