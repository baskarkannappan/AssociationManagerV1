/*
    Script 0015: Stored Procedures Refactoring
    This script defines stored procedures to replace inline SQL queries in the repository layer.
*/

-- PERSONS PROCEDURES
GO
CREATE OR ALTER PROCEDURE sp_Persons_GetById
    @Id INT,
    @TenantId INT,
    @AssociationId INT
AS
BEGIN
    SELECT * FROM Persons 
    WHERE PersonId = @Id AND TenantId = @TenantId AND AssociationId = @AssociationId;
END
GO

CREATE OR ALTER PROCEDURE sp_Persons_GetAll
    @TenantId INT,
    @AssociationId INT
AS
BEGIN
    SELECT * FROM Persons 
    WHERE TenantId = @TenantId AND AssociationId = @AssociationId AND IsActive = 1;
END
GO

CREATE OR ALTER PROCEDURE sp_Persons_Create
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
    INSERT INTO Persons (TenantId, AssociationId, FirstName, LastName, Email, Phone, PhotoUrl, CreatedDate, IsActive)
    OUTPUT INSERTED.PersonId
    VALUES (@TenantId, @AssociationId, @FirstName, @LastName, @Email, @Phone, @PhotoUrl, @CreatedDate, @IsActive);
END
GO

CREATE OR ALTER PROCEDURE sp_Persons_Update
    @PersonId INT,
    @TenantId INT,
    @AssociationId INT,
    @FirstName NVARCHAR(100),
    @LastName NVARCHAR(100),
    @Email NVARCHAR(255),
    @Phone NVARCHAR(50),
    @PhotoUrl NVARCHAR(MAX),
    @IsActive BIT
AS
BEGIN
    UPDATE Persons 
    SET FirstName = @FirstName, 
        LastName = @LastName, 
        Email = @Email, 
        Phone = @Phone, 
        PhotoUrl = @PhotoUrl, 
        IsActive = @IsActive 
    WHERE PersonId = @PersonId AND TenantId = @TenantId AND AssociationId = @AssociationId;
END
GO

CREATE OR ALTER PROCEDURE sp_Persons_Delete
    @Id INT,
    @TenantId INT,
    @AssociationId INT
AS
BEGIN
    UPDATE Persons 
    SET IsActive = 0 
    WHERE PersonId = @Id AND TenantId = @TenantId AND AssociationId = @AssociationId;
END
GO

-- OCCUPANCY PROCEDURES
GO
CREATE OR ALTER PROCEDURE sp_Occupancy_GetByAssetId
    @AssetId INT,
    @TenantId INT,
    @AssociationId INT
AS
BEGIN
    SELECT * FROM Occupancy 
    WHERE AssetId = @AssetId AND TenantId = @TenantId AND AssociationId = @AssociationId;
END
GO

CREATE OR ALTER PROCEDURE sp_Occupancy_Create
    @AssetId INT,
    @PersonId INT,
    @TenantId INT,
    @AssociationId INT,
    @OccupancyType INT,
    @StartDate DATETIME,
    @EndDate DATETIME = NULL,
    @IsPrimaryContact BIT
AS
BEGIN
    INSERT INTO Occupancy (AssetId, PersonId, TenantId, AssociationId, OccupancyType, StartDate, EndDate, IsPrimaryContact)
    OUTPUT INSERTED.OccupancyId
    VALUES (@AssetId, @PersonId, @TenantId, @AssociationId, @OccupancyType, @StartDate, @EndDate, @IsPrimaryContact);
END
GO

CREATE OR ALTER PROCEDURE sp_Occupancy_Delete
    @Id INT,
    @TenantId INT,
    @AssociationId INT
AS
BEGIN
    DELETE FROM Occupancy 
    WHERE OccupancyId = @Id AND TenantId = @TenantId AND AssociationId = @AssociationId;
END
GO

-- ASSETS PROCEDURES
GO
CREATE OR ALTER PROCEDURE sp_Assets_GetById
    @Id INT,
    @TenantId INT,
    @AssociationId INT
AS
BEGIN
    SELECT * FROM Assets 
    WHERE AssetId = @Id AND TenantId = @TenantId AND AssociationId = @AssociationId;
END
GO

CREATE OR ALTER PROCEDURE sp_Assets_GetByParentId
    @ParentId INT = NULL,
    @TenantId INT,
    @AssociationId INT
AS
BEGIN
    IF @ParentId IS NULL
    BEGIN
        SELECT * FROM Assets 
        WHERE TenantId = @TenantId AND AssociationId = @AssociationId AND ParentId IS NULL;
    END
    ELSE
    BEGIN
        SELECT * FROM Assets 
        WHERE TenantId = @TenantId AND AssociationId = @AssociationId AND ParentId = @ParentId;
    END
END
GO

CREATE OR ALTER PROCEDURE sp_Assets_GetHierarchy
    @TenantId INT,
    @AssociationId INT
AS
BEGIN
    SELECT * FROM Assets 
    WHERE TenantId = @TenantId AND AssociationId = @AssociationId AND IsActive = 1 
    ORDER BY ParentId, AssetType;
END
GO

CREATE OR ALTER PROCEDURE sp_Assets_Create
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
    INSERT INTO Assets (ParentId, TenantId, AssociationId, Name, Description, AssetType, MetadataJson, CreatedDate, CreatedBy, IsActive)
    OUTPUT INSERTED.AssetId
    VALUES (@ParentId, @TenantId, @AssociationId, @Name, @Description, @AssetType, @MetadataJson, @CreatedDate, @CreatedBy, @IsActive);
END
GO

CREATE OR ALTER PROCEDURE sp_Assets_Update
    @AssetId INT,
    @TenantId INT,
    @AssociationId INT,
    @ParentId INT = NULL,
    @Name NVARCHAR(255),
    @Description NVARCHAR(MAX),
    @AssetType INT,
    @MetadataJson NVARCHAR(MAX),
    @IsActive BIT
AS
BEGIN
    UPDATE Assets 
    SET ParentId = @ParentId, 
        Name = @Name, 
        Description = @Description, 
        AssetType = @AssetType, 
        MetadataJson = @MetadataJson, 
        IsActive = @IsActive 
    WHERE AssetId = @AssetId AND TenantId = @TenantId AND AssociationId = @AssociationId;
END
GO

CREATE OR ALTER PROCEDURE sp_Assets_Delete
    @Id INT,
    @TenantId INT,
    @AssociationId INT
AS
BEGIN
    UPDATE Assets 
    SET IsActive = 0 
    WHERE AssetId = @Id AND TenantId = @TenantId AND AssociationId = @AssociationId;
END
GO

-- ASSOCIATIONS PROCEDURES
GO
CREATE OR ALTER PROCEDURE sp_Associations_GetById
    @Id INT,
    @TenantId INT
AS
BEGIN
    SELECT * FROM Associations 
    WHERE AssociationId = @Id AND TenantId = @TenantId;
END
GO

CREATE OR ALTER PROCEDURE sp_Associations_GetAllByTenantId
    @TenantId INT
AS
BEGIN
    SELECT * FROM Associations 
    WHERE TenantId = @TenantId;
END
GO

CREATE OR ALTER PROCEDURE sp_Associations_Create
    @TenantId INT,
    @Name NVARCHAR(255),
    @Description NVARCHAR(MAX),
    @CreatedDate DATETIME,
    @CreatedBy NVARCHAR(255)
AS
BEGIN
    INSERT INTO Associations (TenantId, Name, Description, CreatedDate, CreatedBy)
    OUTPUT INSERTED.AssociationId
    VALUES (@TenantId, @Name, @Description, @CreatedDate, @CreatedBy);
END
GO

CREATE OR ALTER PROCEDURE sp_Associations_Update
    @AssociationId INT,
    @TenantId INT,
    @Name NVARCHAR(255),
    @Description NVARCHAR(MAX)
AS
BEGIN
    UPDATE Associations 
    SET Name = @Name, 
        Description = @Description 
    WHERE AssociationId = @AssociationId AND TenantId = @TenantId;
END
GO

CREATE OR ALTER PROCEDURE sp_Associations_Delete
    @Id INT,
    @TenantId INT
AS
BEGIN
    DELETE FROM Associations 
    WHERE AssociationId = @Id AND TenantId = @TenantId;
END
GO

CREATE OR ALTER PROCEDURE sp_Associations_GetByUserId
    @UserId INT
AS
BEGIN
    SELECT a.* 
    FROM Associations a
    INNER JOIN UserAssociations ua ON a.TenantId = ua.TenantId
    WHERE ua.UserId = @UserId;
END
GO

-- USERS PROCEDURES
GO
CREATE OR ALTER PROCEDURE sp_Users_GetById
    @Id INT
AS
BEGIN
    SELECT * FROM Users WHERE UserId = @Id;
END
GO

CREATE OR ALTER PROCEDURE sp_Users_GetByGoogleId
    @GoogleId NVARCHAR(255)
AS
BEGIN
    SELECT * FROM Users WHERE GoogleId = @GoogleId;
END
GO

CREATE OR ALTER PROCEDURE sp_Users_GetByEmail
    @Email NVARCHAR(255)
AS
BEGIN
    SELECT * FROM Users WHERE Email = @Email;
END
GO

CREATE OR ALTER PROCEDURE sp_Users_GetByTenantId
    @TenantId INT
AS
BEGIN
    SELECT u.*, ua.Role 
    FROM Users u
    JOIN UserAssociations ua ON u.UserId = ua.UserId
    WHERE ua.TenantId = @TenantId;
END
GO

CREATE OR ALTER PROCEDURE sp_Users_Create
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
    INSERT INTO Users (TenantId, GoogleId, Email, Name, PictureUrl, Role, CreatedDate, LastLoginDate, IsActive)
    OUTPUT INSERTED.UserId
    VALUES (@TenantId, @GoogleId, @Email, @Name, @PictureUrl, @Role, @CreatedDate, @LastLoginDate, @IsActive);
END
GO

CREATE OR ALTER PROCEDURE sp_Users_Update
    @UserId INT,
    @Name NVARCHAR(255),
    @PictureUrl NVARCHAR(MAX),
    @Role NVARCHAR(50),
    @LastLoginDate DATETIME,
    @IsActive BIT
AS
BEGIN
    UPDATE Users 
    SET Name = @Name, 
        PictureUrl = @PictureUrl, 
        Role = @Role, 
        LastLoginDate = @LastLoginDate, 
        IsActive = @IsActive 
    WHERE UserId = @UserId;
END
GO

-- USER ASSOCIATIONS PROCEDURES
GO
CREATE OR ALTER PROCEDURE sp_UserAssociations_CheckExists
    @UserId INT,
    @TenantId INT
AS
BEGIN
    SELECT COUNT(1) FROM UserAssociations WHERE UserId = @UserId AND TenantId = @TenantId;
END
GO

CREATE OR ALTER PROCEDURE sp_UserAssociations_Upsert
    @UserId INT,
    @TenantId INT,
    @Role NVARCHAR(50)
AS
BEGIN
    IF EXISTS (SELECT 1 FROM UserAssociations WHERE UserId = @UserId AND TenantId = @TenantId)
        UPDATE UserAssociations SET Role = @Role WHERE UserId = @UserId AND TenantId = @TenantId
    ELSE
        INSERT INTO UserAssociations (UserId, TenantId, Role) VALUES (@UserId, @TenantId, @Role);
END
GO

CREATE OR ALTER PROCEDURE sp_UserAssociations_GetRole
    @UserId INT,
    @TenantId INT
AS
BEGIN
    SELECT Role FROM UserAssociations WHERE UserId = @UserId AND TenantId = @TenantId;
END
GO

CREATE OR ALTER PROCEDURE sp_UserAssociations_Delete
    @UserId INT,
    @TenantId INT
AS
BEGIN
    DELETE FROM UserAssociations WHERE UserId = @UserId AND TenantId = @TenantId;
END
GO

-- AUDIT LOGS PROCEDURES
GO
CREATE OR ALTER PROCEDURE sp_AuditLogs_Create
    @TenantId INT,
    @AssociationId INT,
    @UserId INT = NULL,
    @Action NVARCHAR(100),
    @Entity NVARCHAR(100),
    @EntityId INT = NULL,
    @IpAddress NVARCHAR(50) = NULL,
    @Timestamp DATETIME
AS
BEGIN
    INSERT INTO AuditLogs (TenantId, AssociationId, UserId, Action, Entity, EntityId, IpAddress, Timestamp)
    OUTPUT INSERTED.AuditLogId
    VALUES (@TenantId, @AssociationId, @UserId, @Action, @Entity, @EntityId, @IpAddress, @Timestamp);
END
GO

CREATE OR ALTER PROCEDURE sp_AuditLogs_GetByTenantId
    @TenantId INT,
    @AssociationId INT
AS
BEGIN
    SELECT * FROM AuditLogs 
    WHERE TenantId = @TenantId AND AssociationId = @AssociationId 
    ORDER BY Timestamp DESC;
END
GO

-- BROADCASTS PROCEDURES
GO
CREATE OR ALTER PROCEDURE sp_Broadcasts_GetById
    @Id INT,
    @TenantId INT,
    @AssociationId INT
AS
BEGIN
    SELECT b.BroadcastId, b.TenantId, b.Title, b.Content, b.Category, b.CreatedDate, b.CreatedBy, b.IsPinned, b.ExpiresDate, b.AssetId,
           u.Name as AuthorName, a.Name as AssetName
    FROM Broadcasts b 
    LEFT JOIN Users u ON b.CreatedBy = u.UserId
    LEFT JOIN Assets a ON b.AssetId = a.AssetId
    WHERE b.BroadcastId = @Id AND b.TenantId = @TenantId AND b.AssociationId = @AssociationId;
END
GO

CREATE OR ALTER PROCEDURE sp_Broadcasts_GetAll
    @TenantId INT,
    @AssociationId INT
AS
BEGIN
    SELECT b.BroadcastId, b.TenantId, b.Title, b.Content, b.Category, b.CreatedDate, b.CreatedBy, b.IsPinned, b.ExpiresDate, b.AssetId,
           u.Name as AuthorName, a.Name as AssetName
    FROM Broadcasts b 
    LEFT JOIN Users u ON b.CreatedBy = u.UserId
    LEFT JOIN Assets a ON b.AssetId = a.AssetId
    WHERE b.TenantId = @TenantId AND b.AssociationId = @AssociationId
    ORDER BY b.IsPinned DESC, b.CreatedDate DESC;
END
GO

CREATE OR ALTER PROCEDURE sp_Broadcasts_GetByAssetId
    @AssetId INT,
    @TenantId INT,
    @AssociationId INT
AS
BEGIN
    SELECT b.BroadcastId, b.TenantId, b.Title, b.Content, b.Category, b.CreatedDate, b.CreatedBy, b.IsPinned, b.ExpiresDate, b.AssetId,
           u.Name as AuthorName, a.Name as AssetName
    FROM Broadcasts b 
    LEFT JOIN Users u ON b.CreatedBy = u.UserId
    LEFT JOIN Assets a ON b.AssetId = a.AssetId
    WHERE b.TenantId = @TenantId AND b.AssociationId = @AssociationId AND (b.AssetId = @AssetId OR b.AssetId IS NULL)
    ORDER BY b.IsPinned DESC, b.CreatedDate DESC;
END
GO

CREATE OR ALTER PROCEDURE sp_Broadcasts_Create
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
    INSERT INTO Broadcasts (TenantId, AssociationId, Title, Content, Category, CreatedDate, CreatedBy, IsPinned, ExpiresDate, AssetId) 
    OUTPUT INSERTED.BroadcastId 
    VALUES (@TenantId, @AssociationId, @Title, @Content, @Category, @CreatedDate, @CreatedBy, @IsPinned, @ExpiresDate, @AssetId);
END
GO

CREATE OR ALTER PROCEDURE sp_Broadcasts_Delete
    @Id INT,
    @TenantId INT,
    @AssociationId INT
AS
BEGIN
    DELETE FROM Broadcasts WHERE BroadcastId = @Id AND TenantId = @TenantId AND AssociationId = @AssociationId;
END
GO

-- INVOICES PROCEDURES
GO
CREATE OR ALTER PROCEDURE sp_Invoices_GetById
    @Id INT,
    @TenantId INT,
    @AssociationId INT
AS
BEGIN
    SELECT i.*, a.Name as AssetName 
    FROM Invoices i 
    LEFT JOIN Assets a ON i.AssetId = a.AssetId
    WHERE i.InvoiceId = @Id AND i.TenantId = @TenantId AND i.AssociationId = @AssociationId;
END
GO

CREATE OR ALTER PROCEDURE sp_Invoices_GetAll
    @TenantId INT,
    @AssociationId INT
AS
BEGIN
    SELECT i.*, a.Name as AssetName 
    FROM Invoices i 
    LEFT JOIN Assets a ON i.AssetId = a.AssetId
    WHERE i.TenantId = @TenantId AND i.AssociationId = @AssociationId
    ORDER BY i.DueDate DESC;
END
GO

CREATE OR ALTER PROCEDURE sp_Invoices_GetByAssetId
    @AssetId INT,
    @TenantId INT,
    @AssociationId INT
AS
BEGIN
    SELECT i.*, a.Name as AssetName 
    FROM Invoices i 
    LEFT JOIN Assets a ON i.AssetId = a.AssetId
    WHERE i.AssetId = @AssetId AND i.TenantId = @TenantId AND i.AssociationId = @AssociationId
    ORDER BY i.DueDate DESC;
END
GO

CREATE OR ALTER PROCEDURE sp_Invoices_Create
    @TenantId INT,
    @AssociationId INT,
    @AssetId INT = NULL,
    @Title NVARCHAR(200),
    @Description NVARCHAR(MAX) = NULL,
    @Amount DECIMAL(18, 2),
    @DueDate DATETIME,
    @Status NVARCHAR(50),
    @CreatedDate DATETIME
AS
BEGIN
    INSERT INTO Invoices (TenantId, AssociationId, AssetId, Title, Description, Amount, DueDate, Status, CreatedDate) 
    OUTPUT INSERTED.InvoiceId 
    VALUES (@TenantId, @AssociationId, @AssetId, @Title, @Description, @Amount, @DueDate, @Status, @CreatedDate);
END
GO

CREATE OR ALTER PROCEDURE sp_Invoices_UpdateStatus
    @Id INT,
    @Status NVARCHAR(50),
    @TenantId INT,
    @AssociationId INT
AS
BEGIN
    UPDATE Invoices SET Status = @Status 
    WHERE InvoiceId = @Id AND TenantId = @TenantId AND AssociationId = @AssociationId;
END
GO

CREATE OR ALTER PROCEDURE sp_Invoices_Delete
    @Id INT,
    @TenantId INT,
    @AssociationId INT
AS
BEGIN
    DELETE FROM Invoices WHERE InvoiceId = @Id AND TenantId = @TenantId AND AssociationId = @AssociationId;
END
GO

-- PAYMENTS PROCEDURES
GO
CREATE OR ALTER PROCEDURE sp_Payments_GetById
    @Id INT,
    @TenantId INT,
    @AssociationId INT
AS
BEGIN
    SELECT * FROM Payments 
    WHERE PaymentId = @Id AND TenantId = @TenantId AND AssociationId = @AssociationId;
END
GO

CREATE OR ALTER PROCEDURE sp_Payments_GetByTenantId
    @TenantId INT,
    @AssociationId INT
AS
BEGIN
    SELECT * FROM Payments 
    WHERE TenantId = @TenantId AND AssociationId = @AssociationId;
END
GO

CREATE OR ALTER PROCEDURE sp_Payments_Create
    @TenantId INT,
    @AssociationId INT,
    @UserId INT = NULL,
    @Amount DECIMAL(18, 2),
    @Currency NVARCHAR(10),
    @Status NVARCHAR(50),
    @CreatedDate DATETIME,
    @GatewayReference NVARCHAR(255) = NULL
AS
BEGIN
    INSERT INTO Payments (TenantId, AssociationId, UserId, Amount, Currency, Status, CreatedDate, GatewayReference) 
    OUTPUT INSERTED.PaymentId 
    VALUES (@TenantId, @AssociationId, @UserId, @Amount, @Currency, @Status, @CreatedDate, @GatewayReference);
END
GO

CREATE OR ALTER PROCEDURE sp_Payments_UpdateStatus
    @Id INT,
    @Status NVARCHAR(50),
    @GatewayReference NVARCHAR(255) = NULL,
    @TenantId INT,
    @AssociationId INT
AS
BEGIN
    UPDATE Payments SET Status = @Status, GatewayReference = @GatewayReference 
    WHERE PaymentId = @Id AND TenantId = @TenantId AND AssociationId = @AssociationId;
END
GO

-- TARIFF GROUPS PROCEDURES
GO
CREATE OR ALTER PROCEDURE sp_TariffGroups_GetByTenantId
    @TenantId INT
AS
BEGIN
    SELECT * FROM TariffGroups WHERE TenantId = @TenantId;
END
GO

CREATE OR ALTER PROCEDURE sp_TariffGroups_Create
    @TenantId INT,
    @Name NVARCHAR(100),
    @Description NVARCHAR(MAX) = NULL
AS
BEGIN
    INSERT INTO TariffGroups (TenantId, Name, Description) 
    VALUES (@TenantId, @Name, @Description);
    SELECT CAST(SCOPE_IDENTITY() as int);
END
GO

CREATE OR ALTER PROCEDURE sp_TariffGroups_Update
    @TariffGroupId INT,
    @Name NVARCHAR(100),
    @Description NVARCHAR(MAX) = NULL
AS
BEGIN
    UPDATE TariffGroups SET Name = @Name, Description = @Description 
    WHERE TariffGroupId = @TariffGroupId;
END
GO

CREATE OR ALTER PROCEDURE sp_TariffGroups_Delete
    @GroupId INT
AS
BEGIN
    DELETE FROM TariffGroups WHERE TariffGroupId = @GroupId;
END
GO

-- TARIFF LAYERS PROCEDURES
GO
CREATE OR ALTER PROCEDURE sp_TariffLayers_GetByGroupId
    @GroupId INT
AS
BEGIN
    SELECT * FROM TariffLayers WHERE TariffGroupId = @GroupId;
END
GO

CREATE OR ALTER PROCEDURE sp_TariffLayers_Create
    @TariffGroupId INT,
    @TenantId INT,
    @Name NVARCHAR(100),
    @BaseRate DECIMAL(18, 2),
    @Frequency INT,
    @CalculationType INT,
    @AccountingCategory NVARCHAR(100) = NULL
AS
BEGIN
    INSERT INTO TariffLayers (TariffGroupId, TenantId, Name, BaseRate, Frequency, CalculationType, AccountingCategory) 
    VALUES (@TariffGroupId, @TenantId, @Name, @BaseRate, @Frequency, @CalculationType, @AccountingCategory);
    SELECT CAST(SCOPE_IDENTITY() as int);
END
GO

CREATE OR ALTER PROCEDURE sp_TariffLayers_Update
    @TariffLayerId INT,
    @Name NVARCHAR(100),
    @BaseRate DECIMAL(18, 2),
    @Frequency INT,
    @CalculationType INT,
    @AccountingCategory NVARCHAR(100) = NULL
AS
BEGIN
    UPDATE TariffLayers 
    SET Name = @Name, 
        BaseRate = @BaseRate, 
        Frequency = @Frequency, 
        CalculationType = @CalculationType, 
        AccountingCategory = @AccountingCategory 
    WHERE TariffLayerId = @TariffLayerId;
END
GO

CREATE OR ALTER PROCEDURE sp_TariffLayers_Delete
    @LayerId INT
AS
BEGIN
    DELETE FROM TariffLayers WHERE TariffLayerId = @LayerId;
END
GO

-- ASSET TARIFFS PROCEDURES
GO
CREATE OR ALTER PROCEDURE sp_AssetTariffs_GetByAssetId
    @AssetId INT
AS
BEGIN
    SELECT * FROM AssetTariffs WHERE AssetId = @AssetId;
END
GO

CREATE OR ALTER PROCEDURE sp_AssetTariffs_Upsert
    @AssetId INT,
    @TariffLayerId INT,
    @CustomAmount DECIMAL(18, 2) = NULL,
    @IsActive BIT
AS
BEGIN
    IF EXISTS (SELECT 1 FROM AssetTariffs WHERE AssetId = @AssetId AND TariffLayerId = @TariffLayerId)
        UPDATE AssetTariffs SET CustomAmount = @CustomAmount, IsActive = @IsActive 
        WHERE AssetId = @AssetId AND TariffLayerId = @TariffLayerId
    ELSE
        INSERT INTO AssetTariffs (AssetId, TariffLayerId, CustomAmount, IsActive) 
        VALUES (@AssetId, @TariffLayerId, @CustomAmount, @IsActive);
END
GO

CREATE OR ALTER PROCEDURE sp_AssetTariffs_Delete
    @AssetId INT,
    @LayerId INT
AS
BEGIN
    DELETE FROM AssetTariffs WHERE AssetId = @AssetId AND TariffLayerId = @LayerId;
END
GO

CREATE OR ALTER PROCEDURE sp_AssetTariffs_GetActiveByTenantId
    @TenantId INT
AS
BEGIN
    SELECT at.* FROM AssetTariffs at 
    JOIN TariffLayers tl ON at.TariffLayerId = tl.TariffLayerId 
    WHERE tl.TenantId = @TenantId AND at.IsActive = 1;
END
GO

-- TENANTS PROCEDURES
GO
CREATE OR ALTER PROCEDURE sp_Tenants_GetById
    @Id INT
AS
BEGIN
    SELECT * FROM Tenants WHERE TenantId = @Id;
END
GO

CREATE OR ALTER PROCEDURE sp_Tenants_GetAll
AS
BEGIN
    SELECT * FROM Tenants;
END
GO

CREATE OR ALTER PROCEDURE sp_Tenants_Create
    @Name NVARCHAR(255),
    @CreatedDate DATETIME,
    @IsActive BIT
AS
BEGIN
    INSERT INTO Tenants (Name, CreatedDate, IsActive) 
    OUTPUT INSERTED.TenantId 
    VALUES (@Name, @CreatedDate, @IsActive);
END
GO

CREATE OR ALTER PROCEDURE sp_Tenants_Update
    @TenantId INT,
    @Name NVARCHAR(255),
    @IsActive BIT
AS
BEGIN
    UPDATE Tenants SET Name = @Name, IsActive = @IsActive WHERE TenantId = @TenantId;
END
GO

-- TRANSACTIONS PROCEDURES
GO
CREATE OR ALTER PROCEDURE sp_Transactions_Create
    @TenantId INT,
    @AssociationId INT,
    @AssetId INT = NULL,
    @InvoiceId INT = NULL,
    @PaymentId INT = NULL,
    @Type NVARCHAR(50),
    @Amount DECIMAL(18, 2),
    @Category NVARCHAR(100),
    @Description NVARCHAR(MAX) = NULL,
    @TransactionDate DATETIME
AS
BEGIN
    INSERT INTO Transactions (TenantId, AssociationId, AssetId, InvoiceId, PaymentId, Type, Amount, Category, Description, TransactionDate) 
    VALUES (@TenantId, @AssociationId, @AssetId, @InvoiceId, @PaymentId, @Type, @Amount, @Category, @Description, @TransactionDate);
    SELECT CAST(SCOPE_IDENTITY() as bigint);
END
GO

CREATE OR ALTER PROCEDURE sp_Transactions_GetByAssetId
    @AssetId INT,
    @TenantId INT,
    @AssociationId INT
AS
BEGIN
    SELECT * FROM Transactions 
    WHERE AssetId = @AssetId AND TenantId = @TenantId AND AssociationId = @AssociationId 
    ORDER BY TransactionDate DESC;
END
GO

CREATE OR ALTER PROCEDURE sp_Transactions_GetByTenantId
    @TenantId INT,
    @AssociationId INT,
    @StartDate DATETIME = NULL,
    @EndDate DATETIME = NULL
AS
BEGIN
    SELECT * FROM Transactions 
    WHERE TenantId = @TenantId AND AssociationId = @AssociationId
    AND (@StartDate IS NULL OR TransactionDate >= @StartDate)
    AND (@EndDate IS NULL OR TransactionDate <= @EndDate)
    ORDER BY TransactionDate DESC;
END
GO

CREATE OR ALTER PROCEDURE sp_Transactions_GetBalanceByAssetId
    @AssetId INT,
    @TenantId INT,
    @AssociationId INT
AS
BEGIN
    SELECT ISNULL(SUM(CASE WHEN Type = 'Debit' THEN Amount ELSE -Amount END), 0) 
    FROM Transactions 
    WHERE AssetId = @AssetId AND TenantId = @TenantId AND AssociationId = @AssociationId;
END
GO

-- VEHICLES PROCEDURES
GO
CREATE OR ALTER PROCEDURE sp_Vehicles_GetByAssetId
    @AssetId INT,
    @TenantId INT,
    @AssociationId INT
AS
BEGIN
    SELECT * FROM Vehicles 
    WHERE AssetId = @AssetId AND TenantId = @TenantId AND AssociationId = @AssociationId AND IsActive = 1;
END
GO

CREATE OR ALTER PROCEDURE sp_Vehicles_Create
    @AssetId INT,
    @TenantId INT,
    @AssociationId INT,
    @Make NVARCHAR(100),
    @Model NVARCHAR(100),
    @LicensePlate NVARCHAR(50),
    @Color NVARCHAR(50) = NULL,
    @ParkingSlot NVARCHAR(50) = NULL,
	@IsActive BIT
AS
BEGIN
    INSERT INTO Vehicles (AssetId, TenantId, AssociationId, Make, Model, LicensePlate, Color, ParkingSlot, IsActive)
    OUTPUT INSERTED.VehicleId
    VALUES (@AssetId, @TenantId, @AssociationId, @Make, @Model, @LicensePlate, @Color, @ParkingSlot, @IsActive);
END
GO

CREATE OR ALTER PROCEDURE sp_Vehicles_Update
    @VehicleId INT,
    @TenantId INT,
    @AssociationId INT,
    @Make NVARCHAR(100),
    @Model NVARCHAR(100),
    @LicensePlate NVARCHAR(50),
    @Color NVARCHAR(50) = NULL,
    @ParkingSlot NVARCHAR(50) = NULL,
    @IsActive BIT
AS
BEGIN
    UPDATE Vehicles 
    SET Make = @Make, 
        Model = @Model, 
        LicensePlate = @LicensePlate, 
        Color = @Color, 
        ParkingSlot = @ParkingSlot, 
        IsActive = @IsActive 
    WHERE VehicleId = @VehicleId AND TenantId = @TenantId AND AssociationId = @AssociationId;
END
GO

CREATE OR ALTER PROCEDURE sp_Vehicles_Delete
    @Id INT,
    @TenantId INT,
    @AssociationId INT
AS
BEGIN
    UPDATE Vehicles SET IsActive = 0 
    WHERE VehicleId = @Id AND TenantId = @TenantId AND AssociationId = @AssociationId;
END
GO

-- PETS PROCEDURES
GO
CREATE OR ALTER PROCEDURE sp_Pets_GetByAssetId
    @AssetId INT,
    @TenantId INT,
    @AssociationId INT
AS
BEGIN
    SELECT * FROM Pets 
    WHERE AssetId = @AssetId AND TenantId = @TenantId AND AssociationId = @AssociationId AND IsActive = 1;
END
GO

CREATE OR ALTER PROCEDURE sp_Pets_Create
    @AssetId INT,
    @TenantId INT,
    @AssociationId INT,
    @Name NVARCHAR(100),
    @Species NVARCHAR(100),
    @Breed NVARCHAR(100) = NULL,
    @TagNumber NVARCHAR(100) = NULL,
    @IsActive BIT
AS
BEGIN
    INSERT INTO Pets (AssetId, TenantId, AssociationId, Name, Species, Breed, TagNumber, IsActive)
    OUTPUT INSERTED.PetId
    VALUES (@AssetId, @TenantId, @AssociationId, @Name, @Species, @Breed, @TagNumber, @IsActive);
END
GO

CREATE OR ALTER PROCEDURE sp_Pets_Update
    @PetId INT,
    @TenantId INT,
    @AssociationId INT,
    @Name NVARCHAR(100),
    @Species NVARCHAR(100),
    @Breed NVARCHAR(100) = NULL,
    @TagNumber NVARCHAR(100) = NULL,
    @IsActive BIT
AS
BEGIN
    UPDATE Pets 
    SET Name = @Name, 
        Species = @Species, 
        Breed = @Breed, 
        TagNumber = @TagNumber, 
        IsActive = @IsActive 
    WHERE PetId = @PetId AND TenantId = @TenantId AND AssociationId = @AssociationId;
END
GO

CREATE OR ALTER PROCEDURE sp_Pets_Delete
    @Id INT,
    @TenantId INT,
    @AssociationId INT
AS
BEGIN
    UPDATE Pets SET IsActive = 0 
    WHERE PetId = @Id AND TenantId = @TenantId AND AssociationId = @AssociationId;
END
GO

-- WORK ORDERS PROCEDURES
GO
CREATE OR ALTER PROCEDURE sp_WorkOrders_GetById
    @Id INT,
    @TenantId INT,
    @AssociationId INT
AS
BEGIN
    SELECT w.*, a.Name as AssetName 
    FROM WorkOrders w 
    LEFT JOIN Assets a ON w.AssetId = a.AssetId
    WHERE w.WorkOrderId = @Id AND w.TenantId = @TenantId AND w.AssociationId = @AssociationId;
END
GO

CREATE OR ALTER PROCEDURE sp_WorkOrders_GetAll
    @TenantId INT,
    @AssociationId INT
AS
BEGIN
    SELECT w.*, a.Name as AssetName 
    FROM WorkOrders w 
    LEFT JOIN Assets a ON w.AssetId = a.AssetId
    WHERE w.TenantId = @TenantId AND w.AssociationId = @AssociationId
    ORDER BY w.CreatedDate DESC;
END
GO

CREATE OR ALTER PROCEDURE sp_WorkOrders_GetByAssetId
    @AssetId INT,
    @TenantId INT,
    @AssociationId INT
AS
BEGIN
    SELECT w.*, a.Name as AssetName 
    FROM WorkOrders w 
    LEFT JOIN Assets a ON w.AssetId = a.AssetId
    WHERE w.AssetId = @AssetId AND w.TenantId = @TenantId AND w.AssociationId = @AssociationId;
END
GO

CREATE OR ALTER PROCEDURE sp_WorkOrders_Create
    @TenantId INT,
    @AssociationId INT,
    @AssetId INT = NULL,
    @Title NVARCHAR(200),
    @Description NVARCHAR(MAX) = NULL,
    @Priority NVARCHAR(50),
    @Status NVARCHAR(50),
    @CreatedDate DATETIME,
    @CreatedBy INT,
    @AssignedTo INT = NULL
AS
BEGIN
    INSERT INTO WorkOrders (TenantId, AssociationId, AssetId, Title, Description, Priority, Status, CreatedDate, CreatedBy, AssignedTo) 
    OUTPUT INSERTED.WorkOrderId 
    VALUES (@TenantId, @AssociationId, @AssetId, @Title, @Description, @Priority, @Status, @CreatedDate, @CreatedBy, @AssignedTo);
END
GO

CREATE OR ALTER PROCEDURE sp_WorkOrders_Update
    @WorkOrderId INT,
    @TenantId INT,
    @AssociationId INT,
    @AssetId INT = NULL,
    @Title NVARCHAR(200),
    @Description NVARCHAR(MAX) = NULL,
    @Priority NVARCHAR(50),
    @Status NVARCHAR(50),
    @AssignedTo INT = NULL,
    @CompletedDate DATETIME = NULL
AS
BEGIN
    UPDATE WorkOrders 
    SET AssetId = @AssetId, 
        Title = @Title, 
        Description = @Description, 
        Priority = @Priority, 
        Status = @Status, 
        AssignedTo = @AssignedTo, 
        CompletedDate = @CompletedDate
    WHERE WorkOrderId = @WorkOrderId AND TenantId = @TenantId AND AssociationId = @AssociationId;
END
GO

CREATE OR ALTER PROCEDURE sp_WorkOrders_UpdateStatus
    @Id INT,
    @Status NVARCHAR(50),
    @TenantId INT,
    @AssociationId INT
AS
BEGIN
    UPDATE WorkOrders SET Status = @Status 
    WHERE WorkOrderId = @Id AND TenantId = @TenantId AND AssociationId = @AssociationId;
END
GO

CREATE OR ALTER PROCEDURE sp_WorkOrders_Delete
    @Id INT,
    @TenantId INT,
    @AssociationId INT
AS
BEGIN
    DELETE FROM WorkOrders WHERE WorkOrderId = @Id AND TenantId = @TenantId AND AssociationId = @AssociationId;
END
GO
