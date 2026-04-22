CREATE   PROCEDURE corp.sp_Associations_Create 
    @TenantId INT, 
    @Name NVARCHAR(255), 
    @Description NVARCHAR(MAX), 
    @CreatedDate DATETIME, 
    @CreatedBy INT,
    @AdminEmail NVARCHAR(255) = NULL,
    @PlatformAccountId INT = NULL,
    @AdminPaysFee BIT = 1
AS 
BEGIN 
    INSERT INTO corp.Associations (TenantId, Name, Description, CreatedDate, CreatedBy, AdminEmail, PlatformAccountId, AdminPaysFee, Status) 
    VALUES (@TenantId, @Name, @Description, @CreatedDate, @CreatedBy, @AdminEmail, @PlatformAccountId, @AdminPaysFee, 'Active'); 

    SELECT SCOPE_IDENTITY();
END