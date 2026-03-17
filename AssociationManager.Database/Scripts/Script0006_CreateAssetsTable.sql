-- Create Assets Table for Flexible Property Hierarchy
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'Assets')
BEGIN
    CREATE TABLE Assets (
        AssetId INT IDENTITY(1,1) PRIMARY KEY,
        ParentId INT NULL,
        TenantId INT NOT NULL,
        Name NVARCHAR(200) NOT NULL,
        Description NVARCHAR(500),
        AssetType INT NOT NULL, -- Enum: Property=1, Building=2, Floor=3, Unit=4...
        MetadataJson NVARCHAR(MAX), -- For custom fields
        CreatedDate DATETIME NOT NULL DEFAULT GETDATE(),
        CreatedBy INT,
        IsActive BIT NOT NULL DEFAULT 1,
        
        -- Self-referencing FK for hierarchy
        CONSTRAINT FK_Assets_Parent FOREIGN KEY (ParentId) REFERENCES Assets(AssetId),
        
        -- Multi-tenancy enforcement
        CONSTRAINT FK_Assets_Tenants FOREIGN KEY (TenantId) REFERENCES Tenants(TenantId)
    );

    -- Indexes for efficient hierarchy traversal and tenant isolation
    CREATE INDEX IX_Assets_TenantId ON Assets(TenantId);
    CREATE INDEX IX_Assets_ParentId ON Assets(ParentId);
    CREATE INDEX IX_Assets_AssetType ON Assets(AssetType);
END
GO
