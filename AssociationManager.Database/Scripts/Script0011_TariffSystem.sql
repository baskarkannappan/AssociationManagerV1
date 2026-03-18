USE AssociationManagerV1;
GO

-- Tariff Groups
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'TariffGroups')
BEGIN
    CREATE TABLE TariffGroups (
        TariffGroupId INT IDENTITY(1,1) PRIMARY KEY,
        TenantId INT NOT NULL,
        Name NVARCHAR(100) NOT NULL,
        Description NVARCHAR(500),
        CONSTRAINT FK_TariffGroups_Tenants FOREIGN KEY (TenantId) REFERENCES Tenants(TenantId)
    );
END
GO

-- Tariff Layers
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'TariffLayers')
BEGIN
    CREATE TABLE TariffLayers (
        TariffLayerId INT IDENTITY(1,1) PRIMARY KEY,
        TariffGroupId INT NOT NULL,
        TenantId INT NOT NULL,
        Name NVARCHAR(100) NOT NULL,
        BaseRate DECIMAL(18,2) NOT NULL,
        Frequency INT NOT NULL, -- Enum
        CalculationType INT NOT NULL, -- Enum
        AccountingCategory NVARCHAR(100),
        CONSTRAINT FK_TariffLayers_Groups FOREIGN KEY (TariffGroupId) REFERENCES TariffGroups(TariffGroupId),
        CONSTRAINT FK_TariffLayers_Tenants FOREIGN KEY (TenantId) REFERENCES Tenants(TenantId)
    );
END
GO

-- Asset Tariffs (Attachments)
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'AssetTariffs')
BEGIN
    CREATE TABLE AssetTariffs (
        AssetId INT NOT NULL,
        TariffLayerId INT NOT NULL,
        CustomAmount DECIMAL(18,2), -- Override
        IsActive BIT NOT NULL DEFAULT 1,
        PRIMARY KEY (AssetId, TariffLayerId),
        CONSTRAINT FK_AssetTariffs_Assets FOREIGN KEY (AssetId) REFERENCES Assets(AssetId),
        CONSTRAINT FK_AssetTariffs_Layers FOREIGN KEY (TariffLayerId) REFERENCES TariffLayers(TariffLayerId)
    );
END
GO

-- Transactions (General Ledger)
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'Transactions')
BEGIN
    CREATE TABLE Transactions (
        TransactionId BIGINT IDENTITY(1,1) PRIMARY KEY,
        TenantId INT NOT NULL,
        AssetId INT NOT NULL,
        InvoiceId INT,
        PaymentId INT,
        Type NVARCHAR(10) NOT NULL, -- Debit/Credit
        Amount DECIMAL(18,2) NOT NULL,
        Category NVARCHAR(100) NOT NULL,
        Description NVARCHAR(500),
        TransactionDate DATETIME NOT NULL DEFAULT GETDATE(),
        CONSTRAINT FK_Transactions_Tenants FOREIGN KEY (TenantId) REFERENCES Tenants(TenantId),
        CONSTRAINT FK_Transactions_Assets FOREIGN KEY (AssetId) REFERENCES Assets(AssetId)
    );
END
GO
