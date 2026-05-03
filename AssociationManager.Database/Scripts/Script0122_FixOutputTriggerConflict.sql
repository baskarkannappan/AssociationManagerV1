-- Script 0122: Fix OUTPUT clause conflict with triggers in creation stored procedures
-- Refactored to use SCOPE_IDENTITY() for trigger compatibility

-- 1. corp.sp_Associations_Create [CRITICAL FIX]
GO
CREATE OR ALTER PROCEDURE corp.sp_Associations_Create 
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
GO

-- 2. corp.sp_Tenants_Create
CREATE OR ALTER PROCEDURE corp.sp_Tenants_Create 
    @Name NVARCHAR(255), 
    @CreatedDate DATETIME, 
    @IsActive BIT 
AS 
BEGIN 
    INSERT INTO corp.Tenants (Name, CreatedDate, IsActive) 
    VALUES (@Name, @CreatedDate, @IsActive); 

    SELECT SCOPE_IDENTITY();
END
GO

-- 3. corp.sp_Users_Create
CREATE OR ALTER PROCEDURE corp.sp_Users_Create 
    @TenantId INT, 
    @GoogleId NVARCHAR(255) = NULL, 
    @Email NVARCHAR(255), 
    @Name NVARCHAR(255), 
    @PictureUrl NVARCHAR(MAX), 
    @Role NVARCHAR(50), 
    @CreatedDate DATETIME, 
    @LastLoginDate DATETIME = NULL, 
    @IsActive BIT 
AS 
BEGIN 
    INSERT INTO corp.Users (TenantId, GoogleId, Email, Name, PictureUrl, Role, CreatedDate, LastLoginDate, IsActive) 
    VALUES (@TenantId, @GoogleId, @Email, @Name, @PictureUrl, @Role, @CreatedDate, @LastLoginDate, @IsActive); 

    SELECT SCOPE_IDENTITY();
END
GO

-- 4. assoc.sp_Assets_Create
CREATE OR ALTER PROCEDURE assoc.sp_Assets_Create 
    @ParentId INT = NULL, 
    @TenantId INT, 
    @AssociationId INT, 
    @Name NVARCHAR(255), 
    @Description NVARCHAR(MAX), 
    @AssetType INT, 
    @MetadataJson NVARCHAR(MAX), 
    @CreatedDate DATETIME, 
    @CreatedBy NVARCHAR(255), 
    @IsActive BIT 
AS 
BEGIN 
    SET NOCOUNT ON; 
    
    IF @ParentId IS NOT NULL AND NOT EXISTS (
        SELECT 1 FROM assoc.Assets 
        WHERE AssetId = @ParentId AND AssociationId = @AssociationId
    ) 
    BEGIN 
        SET @ParentId = NULL; 
    END 
    
    INSERT INTO assoc.Assets (ParentId, TenantId, AssociationId, Name, Description, AssetType, MetadataJson, CreatedDate, CreatedBy, IsActive) 
    VALUES (@ParentId, @TenantId, @AssociationId, @Name, @Description, @AssetType, @MetadataJson, @CreatedDate, @CreatedBy, @IsActive); 
    
    SELECT SCOPE_IDENTITY();
END
GO

-- 5. assoc.sp_BillingBatches_Create
CREATE OR ALTER PROCEDURE assoc.sp_BillingBatches_Create 
    @TenantId INT, 
    @AssociationId INT, 
    @Month INT, 
    @Year INT, 
    @Status NVARCHAR(50), 
    @TotalAmount DECIMAL(18,2), 
    @InvoicesGenerated INT, 
    @CreatedDate DATETIME 
AS 
BEGIN 
    INSERT INTO assoc.BillingBatches (TenantId, AssociationId, Month, Year, Status, TotalAmount, InvoicesGenerated, CreatedDate) 
    VALUES (@TenantId, @AssociationId, @Month, @Year, @Status, @TotalAmount, @InvoicesGenerated, @CreatedDate); 

    SELECT SCOPE_IDENTITY();
END
GO

-- 6. assoc.sp_InvoiceLineItems_Create
CREATE OR ALTER PROCEDURE assoc.sp_InvoiceLineItems_Create 
    @InvoiceId INT, 
    @ChargeName NVARCHAR(200), 
    @Amount DECIMAL(18,2), 
    @Description NVARCHAR(MAX), 
    @TariffLayerId INT = NULL, 
    @Rate DECIMAL(18,2) = NULL 
AS 
BEGIN 
    INSERT INTO assoc.InvoiceLineItems (InvoiceId, ChargeName, Amount, Description, TariffLayerId, Rate) 
    VALUES (@InvoiceId, @ChargeName, @Amount, @Description, @TariffLayerId, @Rate); 

    SELECT SCOPE_IDENTITY();
END
GO

-- 7. assoc.sp_Persons_Create
CREATE OR ALTER PROCEDURE assoc.sp_Persons_Create 
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
GO

-- 8. assoc.sp_Pets_Create
CREATE OR ALTER PROCEDURE assoc.sp_Pets_Create 
    @AssetId INT, 
    @TenantId INT, 
    @AssociationId INT, 
    @Name NVARCHAR(100), 
    @Species NVARCHAR(100), 
    @Breed NVARCHAR(100), 
    @TagNumber NVARCHAR(50), 
    @IsActive BIT 
AS 
BEGIN 
    INSERT INTO assoc.Pets (AssetId, TenantId, AssociationId, Name, Species, Breed, TagNumber, IsActive) 
    VALUES (@AssetId, @TenantId, @AssociationId, @Name, @Species, @Breed, @TagNumber, @IsActive); 

    SELECT SCOPE_IDENTITY();
END
GO

-- 9. assoc.sp_Vehicles_Create
CREATE OR ALTER PROCEDURE assoc.sp_Vehicles_Create 
    @AssetId INT, 
    @TenantId INT, 
    @AssociationId INT, 
    @Make NVARCHAR(100), 
    @Model NVARCHAR(100), 
    @LicensePlate NVARCHAR(50), 
    @Color NVARCHAR(50), 
    @ParkingSlot NVARCHAR(100), 
    @IsActive BIT 
AS 
BEGIN 
    INSERT INTO assoc.Vehicles (AssetId, TenantId, AssociationId, Make, Model, LicensePlate, Color, ParkingSlot, IsActive) 
    VALUES (@AssetId, @TenantId, @AssociationId, @Make, @Model, @LicensePlate, @Color, @ParkingSlot, @IsActive); 

    SELECT SCOPE_IDENTITY();
END
GO

-- 10. assoc.sp_Broadcasts_Create
CREATE OR ALTER PROCEDURE assoc.sp_Broadcasts_Create 
    @TenantId INT, 
    @AssociationId INT, 
    @Title NVARCHAR(200), 
    @Content NVARCHAR(MAX), 
    @Category NVARCHAR(50), 
    @CreatedDate DATETIME, 
    @CreatedBy INT, 
    @IsPinned BIT, 
    @ExpiresDate DATETIME = NULL, 
    @AssetId INT = NULL 
AS 
BEGIN 
    INSERT INTO assoc.Broadcasts (TenantId, AssociationId, Title, Content, Category, CreatedDate, CreatedBy, IsPinned, ExpiresDate, AssetId) 
    VALUES (@TenantId, @AssociationId, @Title, @Content, @Category, @CreatedDate, @CreatedBy, @IsPinned, @ExpiresDate, @AssetId); 

    SELECT SCOPE_IDENTITY();
END
GO

-- 11. sp_TariffLayers_Create
CREATE OR ALTER PROCEDURE sp_TariffLayers_Create
    @TariffGroupId INT,
    @TenantId INT,
    @AssociationId INT = NULL,
    @Name NVARCHAR(100),
    @BaseRate DECIMAL(18, 2),
    @Frequency NVARCHAR(50),
    @CalculationType NVARCHAR(50),
    @AccountingCategory NVARCHAR(100) = NULL
AS
BEGIN
    INSERT INTO TariffLayers (TariffGroupId, TenantId, AssociationId, Name, BaseRate, Frequency, CalculationType, AccountingCategory)
    VALUES (@TariffGroupId, @TenantId, @AssociationId, @Name, @BaseRate, @Frequency, @CalculationType, @AccountingCategory);

    SELECT SCOPE_IDENTITY();
END
GO

-- 12. sp_TariffGroups_Create
CREATE OR ALTER PROCEDURE sp_TariffGroups_Create
    @TenantId INT,
    @AssociationId INT = NULL,
    @Name NVARCHAR(100),
    @Description NVARCHAR(MAX) = NULL
AS
BEGIN
    INSERT INTO TariffGroups (TenantId, AssociationId, Name, Description)
    VALUES (@TenantId, @AssociationId, @Name, @Description);

    SELECT SCOPE_IDENTITY();
END
GO
