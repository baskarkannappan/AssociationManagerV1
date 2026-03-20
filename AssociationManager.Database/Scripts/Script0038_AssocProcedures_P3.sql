-- BROADCASTS
CREATE OR ALTER PROCEDURE assoc.sp_Broadcasts_GetById @Id INT, @TenantId INT, @AssociationId INT AS 
BEGIN
    SELECT b.*, u.Name as AuthorName, a.Name as AssetName
    FROM assoc.Broadcasts b 
    LEFT JOIN corp.Users u ON b.CreatedBy = u.UserId
    LEFT JOIN assoc.Assets a ON b.AssetId = a.AssetId
    WHERE b.BroadcastId = @Id AND b.TenantId = @TenantId AND b.AssociationId = @AssociationId;
END
GO
CREATE OR ALTER PROCEDURE assoc.sp_Broadcasts_GetAll @TenantId INT, @AssociationId INT AS 
BEGIN
    SELECT b.*, u.Name as AuthorName, a.Name as AssetName
    FROM assoc.Broadcasts b 
    LEFT JOIN corp.Users u ON b.CreatedBy = u.UserId
    LEFT JOIN assoc.Assets a ON b.AssetId = a.AssetId
    WHERE b.TenantId = @TenantId AND b.AssociationId = @AssociationId
    ORDER BY b.IsPinned DESC, b.CreatedDate DESC;
END
GO
CREATE OR ALTER PROCEDURE assoc.sp_Broadcasts_GetByAssetId @AssetId INT, @TenantId INT, @AssociationId INT AS 
BEGIN
    SELECT b.*, u.Name as AuthorName, a.Name as AssetName
    FROM assoc.Broadcasts b 
    LEFT JOIN corp.Users u ON b.CreatedBy = u.UserId
    LEFT JOIN assoc.Assets a ON b.AssetId = a.AssetId
    WHERE b.TenantId = @TenantId AND b.AssociationId = @AssociationId AND (b.AssetId = @AssetId OR b.AssetId IS NULL)
    ORDER BY b.IsPinned DESC, b.CreatedDate DESC;
END
GO
CREATE OR ALTER PROCEDURE assoc.sp_Broadcasts_Create @TenantId INT, @AssociationId INT, @Title NVARCHAR(200), @Content NVARCHAR(MAX), @Category NVARCHAR(50), @CreatedDate DATETIME, @CreatedBy INT, @IsPinned BIT, @ExpiresDate DATETIME = NULL, @AssetId INT = NULL AS 
BEGIN INSERT INTO assoc.Broadcasts (TenantId, AssociationId, Title, Content, Category, CreatedDate, CreatedBy, IsPinned, ExpiresDate, AssetId) OUTPUT INSERTED.BroadcastId VALUES (@TenantId, @AssociationId, @Title, @Content, @Category, @CreatedDate, @CreatedBy, @IsPinned, @ExpiresDate, @AssetId); END
GO
CREATE OR ALTER PROCEDURE assoc.sp_Broadcasts_Delete @Id INT, @TenantId INT, @AssociationId INT AS 
BEGIN DELETE FROM assoc.Broadcasts WHERE BroadcastId = @Id AND TenantId = @TenantId AND AssociationId = @AssociationId; END
GO

-- TARIFF GROUPS
CREATE OR ALTER PROCEDURE assoc.sp_TariffGroups_GetByTenantId @TenantId INT, @AssociationId INT = NULL AS 
BEGIN SELECT * FROM assoc.TariffGroups WHERE TenantId = @TenantId AND (AssociationId = @AssociationId OR (@AssociationId IS NULL AND AssociationId IS NULL)); END
GO
CREATE OR ALTER PROCEDURE assoc.sp_TariffGroups_Create @TenantId INT, @AssociationId INT = NULL, @Name NVARCHAR(100), @Description NVARCHAR(MAX) = NULL AS 
BEGIN INSERT INTO assoc.TariffGroups (TenantId, AssociationId, Name, Description) VALUES (@TenantId, @AssociationId, @Name, @Description); SELECT CAST(SCOPE_IDENTITY() as int); END
GO
CREATE OR ALTER PROCEDURE assoc.sp_TariffGroups_Update @TariffGroupId INT, @Name NVARCHAR(100), @Description NVARCHAR(MAX) = NULL AS 
BEGIN UPDATE assoc.TariffGroups SET Name = @Name, Description = @Description WHERE TariffGroupId = @TariffGroupId; END
GO
CREATE OR ALTER PROCEDURE assoc.sp_TariffGroups_Delete @GroupId INT AS 
BEGIN DELETE FROM assoc.TariffGroups WHERE TariffGroupId = @GroupId; END
GO

-- TARIFF LAYERS
CREATE OR ALTER PROCEDURE assoc.sp_TariffLayers_GetByGroupId @GroupId INT AS 
BEGIN SELECT * FROM assoc.TariffLayers WHERE TariffGroupId = @GroupId; END
GO
CREATE OR ALTER PROCEDURE assoc.sp_TariffLayers_Create @TariffGroupId INT, @TenantId INT, @Name NVARCHAR(100), @BaseRate DECIMAL(18, 2), @Frequency INT, @CalculationType INT, @AccountingCategory NVARCHAR(100) = NULL AS 
BEGIN INSERT INTO assoc.TariffLayers (TariffGroupId, TenantId, Name, BaseRate, Frequency, CalculationType, AccountingCategory) VALUES (@TariffGroupId, @TenantId, @Name, @BaseRate, @Frequency, @CalculationType, @AccountingCategory); SELECT CAST(SCOPE_IDENTITY() as int); END
GO
CREATE OR ALTER PROCEDURE assoc.sp_TariffLayers_Update @TariffLayerId INT, @Name NVARCHAR(100), @BaseRate DECIMAL(18, 2), @Frequency INT, @CalculationType INT, @AccountingCategory NVARCHAR(100) = NULL AS 
BEGIN UPDATE assoc.TariffLayers SET Name = @Name, BaseRate = @BaseRate, Frequency = @Frequency, CalculationType = @CalculationType, AccountingCategory = @AccountingCategory WHERE TariffLayerId = @TariffLayerId; END
GO
CREATE OR ALTER PROCEDURE assoc.sp_TariffLayers_Delete @LayerId INT AS 
BEGIN DELETE FROM assoc.TariffLayers WHERE TariffLayerId = @LayerId; END
GO

-- ASSET TARIFFS
CREATE OR ALTER PROCEDURE assoc.sp_AssetTariffs_GetByAssetId @AssetId INT AS 
BEGIN SELECT * FROM assoc.AssetTariffs WHERE AssetId = @AssetId; END
GO
CREATE OR ALTER PROCEDURE assoc.sp_AssetTariffs_Upsert @AssetId INT, @TariffLayerId INT, @CustomAmount DECIMAL(18, 2) = NULL, @IsActive BIT AS 
BEGIN IF EXISTS (SELECT 1 FROM assoc.AssetTariffs WHERE AssetId = @AssetId AND TariffLayerId = @TariffLayerId) UPDATE assoc.AssetTariffs SET CustomAmount = @CustomAmount, IsActive = @IsActive WHERE AssetId = @AssetId AND TariffLayerId = @TariffLayerId ELSE INSERT INTO assoc.AssetTariffs (AssetId, TariffLayerId, CustomAmount, IsActive) VALUES (@AssetId, @TariffLayerId, @CustomAmount, @IsActive); END
GO
CREATE OR ALTER PROCEDURE assoc.sp_AssetTariffs_Delete @AssetId INT, @LayerId INT AS 
BEGIN DELETE FROM assoc.AssetTariffs WHERE AssetId = @AssetId AND TariffLayerId = @LayerId; END
GO
CREATE OR ALTER PROCEDURE assoc.sp_AssetTariffs_GetActiveByTenantId @TenantId INT AS 
BEGIN SELECT at.* FROM assoc.AssetTariffs at JOIN assoc.TariffLayers tl ON at.TariffLayerId = tl.TariffLayerId WHERE tl.TenantId = @TenantId AND at.IsActive = 1; END
GO

-- VEHICLES
CREATE OR ALTER PROCEDURE assoc.sp_Vehicles_GetByAssetId @AssetId INT, @TenantId INT, @AssociationId INT AS 
BEGIN SELECT * FROM assoc.Vehicles WHERE AssetId = @AssetId AND TenantId = @TenantId AND AssociationId = @AssociationId; END
GO
CREATE OR ALTER PROCEDURE assoc.sp_Vehicles_Create @AssetId INT, @TenantId INT, @AssociationId INT, @Make NVARCHAR(100), @Model NVARCHAR(100), @LicensePlate NVARCHAR(50), @Color NVARCHAR(50), @ParkingSlot NVARCHAR(100), @IsActive BIT AS 
BEGIN INSERT INTO assoc.Vehicles (AssetId, TenantId, AssociationId, Make, Model, LicensePlate, Color, ParkingSlot, IsActive) OUTPUT INSERTED.VehicleId VALUES (@AssetId, @TenantId, @AssociationId, @Make, @Model, @LicensePlate, @Color, @ParkingSlot, @IsActive); END
GO
CREATE OR ALTER PROCEDURE assoc.sp_Vehicles_Delete @Id INT, @TenantId INT, @AssociationId INT AS 
BEGIN DELETE FROM assoc.Vehicles WHERE VehicleId = @Id AND TenantId = @TenantId AND AssociationId = @AssociationId; END
GO

-- PETS
CREATE OR ALTER PROCEDURE assoc.sp_Pets_GetByAssetId @AssetId INT, @TenantId INT, @AssociationId INT AS 
BEGIN SELECT * FROM assoc.Pets WHERE AssetId = @AssetId AND TenantId = @TenantId AND AssociationId = @AssociationId; END
GO
CREATE OR ALTER PROCEDURE assoc.sp_Pets_Create @AssetId INT, @TenantId INT, @AssociationId INT, @Name NVARCHAR(100), @Species NVARCHAR(100), @Breed NVARCHAR(100), @TagNumber NVARCHAR(50), @IsActive BIT AS 
BEGIN INSERT INTO assoc.Pets (AssetId, TenantId, AssociationId, Name, Species, Breed, TagNumber, IsActive) OUTPUT INSERTED.PetId VALUES (@AssetId, @TenantId, @AssociationId, @Name, @Species, @Breed, @TagNumber, @IsActive); END
GO
CREATE OR ALTER PROCEDURE assoc.sp_Pets_Delete @Id INT, @TenantId INT, @AssociationId INT AS 
BEGIN DELETE FROM assoc.Pets WHERE PetId = @Id AND TenantId = @TenantId AND AssociationId = @AssociationId; END
GO
