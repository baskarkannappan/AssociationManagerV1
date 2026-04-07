-- 5. Update sp_Associations_Update
CREATE   PROCEDURE corp.sp_Associations_Update 
    @AssociationId INT, 
    @TenantId INT, 
    @Name NVARCHAR(255), 
    @Description NVARCHAR(MAX),
    @AdminEmail NVARCHAR(255) = NULL,
    @PlatformAccountId INT = NULL,
    @AdminPaysFee BIT = 1,
    @Status NVARCHAR(50) = 'Active'
AS 
BEGIN 
    UPDATE corp.Associations 
    SET Name = @Name, 
        Description = @Description,
        AdminEmail = ISNULL(@AdminEmail, AdminEmail),
        PlatformAccountId = @PlatformAccountId,
        AdminPaysFee = @AdminPaysFee,
        Status = @Status
    WHERE AssociationId = @AssociationId AND TenantId = @TenantId; 
END