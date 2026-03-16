USE AssociationManagerV1;
GO

-- Tenants Table
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'Tenants')
BEGIN
    CREATE TABLE Tenants (
        TenantId INT IDENTITY(1,1) PRIMARY KEY,
        Name NVARCHAR(200) NOT NULL,
        CreatedDate DATETIME NOT NULL DEFAULT GETDATE(),
        IsActive BIT NOT NULL DEFAULT 1
    );
END
GO

-- Users Table
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'Users')
BEGIN
    CREATE TABLE Users (
        UserId INT IDENTITY(1,1) PRIMARY KEY,
        TenantId INT NOT NULL,
        GoogleId NVARCHAR(200) NOT NULL,
        Email NVARCHAR(200) NOT NULL,
        Name NVARCHAR(200) NOT NULL,
        PictureUrl NVARCHAR(500),
        CreatedDate DATETIME NOT NULL DEFAULT GETDATE(),
        LastLoginDate DATETIME,
        IsActive BIT NOT NULL DEFAULT 1,
        CONSTRAINT FK_Users_Tenants FOREIGN KEY (TenantId) REFERENCES Tenants(TenantId)
    );
END
GO

-- RefreshTokens Table
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'RefreshTokens')
BEGIN
    CREATE TABLE RefreshTokens (
        RefreshTokenId INT IDENTITY(1,1) PRIMARY KEY,
        UserId INT NOT NULL,
        Token NVARCHAR(500) NOT NULL,
        ExpiryDate DATETIME NOT NULL,
        CreatedDate DATETIME NOT NULL DEFAULT GETDATE(),
        IsRevoked BIT NOT NULL DEFAULT 0,
        CONSTRAINT FK_RefreshTokens_Users FOREIGN KEY (UserId) REFERENCES Users(UserId)
    );
END
GO

-- Associations Table
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'Associations')
BEGIN
    CREATE TABLE Associations (
        AssociationId INT IDENTITY(1,1) PRIMARY KEY,
        TenantId INT NOT NULL,
        Name NVARCHAR(200) NOT NULL,
        Description NVARCHAR(500),
        CreatedDate DATETIME NOT NULL DEFAULT GETDATE(),
        CreatedBy INT,
        CONSTRAINT FK_Associations_Tenants FOREIGN KEY (TenantId) REFERENCES Tenants(TenantId)
    );
END
GO

-- AuditLogs Table
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'AuditLogs')
BEGIN
    CREATE TABLE AuditLogs (
        AuditLogId INT IDENTITY(1,1) PRIMARY KEY,
        TenantId INT NOT NULL,
        UserId INT,
        Action NVARCHAR(200) NOT NULL,
        Entity NVARCHAR(200),
        EntityId INT,
        IpAddress NVARCHAR(100),
        Timestamp DATETIME NOT NULL DEFAULT GETDATE(),
        CONSTRAINT FK_AuditLogs_Tenants FOREIGN KEY (TenantId) REFERENCES Tenants(TenantId)
    );
END
GO

-- Payments Table
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'Payments')
BEGIN
    CREATE TABLE Payments (
        PaymentId INT IDENTITY(1,1) PRIMARY KEY,
        TenantId INT NOT NULL,
        UserId INT NOT NULL,
        Amount DECIMAL(18,2) NOT NULL,
        Currency NVARCHAR(10) NOT NULL,
        Status NVARCHAR(50) NOT NULL,
        CreatedDate DATETIME NOT NULL DEFAULT GETDATE(),
        GatewayReference NVARCHAR(200),
        CONSTRAINT FK_Payments_Tenants FOREIGN KEY (TenantId) REFERENCES Tenants(TenantId)
    );
END
GO
