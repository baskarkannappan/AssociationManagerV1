-- People, Occupancy, Vehicles, and Pets for units
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'Persons')
BEGIN
    CREATE TABLE Persons (
        PersonId INT IDENTITY(1,1) PRIMARY KEY,
        TenantId INT NOT NULL,
        FirstName NVARCHAR(100) NOT NULL,
        LastName NVARCHAR(100) NOT NULL,
        Email NVARCHAR(200),
        Phone NVARCHAR(50),
        PhotoUrl NVARCHAR(500),
        CreatedDate DATETIME NOT NULL DEFAULT GETDATE(),
        IsActive BIT NOT NULL DEFAULT 1,
        CONSTRAINT FK_Persons_Tenants FOREIGN KEY (TenantId) REFERENCES Tenants(TenantId)
    );
END

IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'Occupancy')
BEGIN
    CREATE TABLE Occupancy (
        OccupancyId INT IDENTITY(1,1) PRIMARY KEY,
        AssetId INT NOT NULL, -- The Unit
        PersonId INT NOT NULL,
        TenantId INT NOT NULL,
        OccupancyType INT NOT NULL, -- Enum: Owner=1, Tenant=2...
        StartDate DATETIME,
        EndDate DATETIME,
        IsPrimaryContact BIT NOT NULL DEFAULT 0,
        CONSTRAINT FK_Occupancy_Assets FOREIGN KEY (AssetId) REFERENCES Assets(AssetId),
        CONSTRAINT FK_Occupancy_Persons FOREIGN KEY (PersonId) REFERENCES Persons(PersonId),
        CONSTRAINT FK_Occupancy_Tenants FOREIGN KEY (TenantId) REFERENCES Tenants(TenantId)
    );
END

IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'Vehicles')
BEGIN
    CREATE TABLE Vehicles (
        VehicleId INT IDENTITY(1,1) PRIMARY KEY,
        AssetId INT NOT NULL,
        TenantId INT NOT NULL,
        Make NVARCHAR(100) NOT NULL,
        Model NVARCHAR(100) NOT NULL,
        LicensePlate NVARCHAR(50) NOT NULL,
        Color NVARCHAR(50),
        ParkingSlot NVARCHAR(100),
        IsActive BIT NOT NULL DEFAULT 1,
        CONSTRAINT FK_Vehicles_Assets FOREIGN KEY (AssetId) REFERENCES Assets(AssetId),
        CONSTRAINT FK_Vehicles_Tenants FOREIGN KEY (TenantId) REFERENCES Tenants(TenantId)
    );
END

IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'Pets')
BEGIN
    CREATE TABLE Pets (
        PetId INT IDENTITY(1,1) PRIMARY KEY,
        AssetId INT NOT NULL,
        TenantId INT NOT NULL,
        Name NVARCHAR(100) NOT NULL,
        Species NVARCHAR(50) NOT NULL,
        Breed NVARCHAR(100),
        TagNumber NVARCHAR(100),
        IsActive BIT NOT NULL DEFAULT 1,
        CONSTRAINT FK_Pets_Assets FOREIGN KEY (AssetId) REFERENCES Assets(AssetId),
        CONSTRAINT FK_Pets_Tenants FOREIGN KEY (TenantId) REFERENCES Tenants(TenantId)
    );
END
GO
