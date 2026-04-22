-- 7. assoc.sp_Persons_Create
CREATE   PROCEDURE assoc.sp_Persons_Create 
    @TenantId INT, 
    @AssociationId INT, 
    @FirstName NVARCHAR(100), 
    @LastName NVARCHAR(100), 
    @Email NVARCHAR(255), 
    @Phone NVARCHAR(50), 
    @PhotoUrl NVARCHAR(MAX), 
    @CreatedDate DATETIME, 
    @IsActive BIT 
AS 
BEGIN 
    INSERT INTO assoc.Persons (TenantId, AssociationId, FirstName, LastName, Email, Phone, PhotoUrl, CreatedDate, IsActive) 
    VALUES (@TenantId, @AssociationId, @FirstName, @LastName, @Email, @Phone, @PhotoUrl, @CreatedDate, @IsActive); 

    SELECT SCOPE_IDENTITY();
END