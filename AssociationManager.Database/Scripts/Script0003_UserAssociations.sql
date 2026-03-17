IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'UserAssociations')
BEGIN
    CREATE TABLE UserAssociations (
        UserId INT NOT NULL,
        TenantId INT NOT NULL,
        Role NVARCHAR(50) NOT NULL,
        CreatedDate DATETIME2 NOT NULL DEFAULT GETUTCDATE(),
        PRIMARY KEY (UserId, TenantId),
        FOREIGN KEY (UserId) REFERENCES Users(UserId),
        FOREIGN KEY (TenantId) REFERENCES Tenants(TenantId)
    );

    CREATE INDEX IX_UserAssociations_UserId ON UserAssociations(UserId);
    CREATE INDEX IX_UserAssociations_TenantId ON UserAssociations(TenantId);
END
GO
