USE AssociationManagerV1;
GO

-- Broadcasts Table
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'Broadcasts')
BEGIN
    CREATE TABLE Broadcasts (
        BroadcastId INT IDENTITY(1,1) PRIMARY KEY,
        TenantId INT NOT NULL,
        Title NVARCHAR(200) NOT NULL,
        Content NVARCHAR(MAX) NOT NULL,
        Category NVARCHAR(50) NOT NULL DEFAULT 'General', -- General, Emergency, Maintenance, Social
        CreatedDate DATETIME NOT NULL DEFAULT GETDATE(),
        CreatedBy INT NOT NULL,
        IsPinned BIT NOT NULL DEFAULT 0,
        ExpiresDate DATETIME,
        CONSTRAINT FK_Broadcasts_Tenants FOREIGN KEY (TenantId) REFERENCES Tenants(TenantId)
    );
END
GO
