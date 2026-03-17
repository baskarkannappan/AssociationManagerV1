USE AssociationManagerV1;
GO

-- WorkOrders Table
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'WorkOrders')
BEGIN
    CREATE TABLE WorkOrders (
        WorkOrderId INT IDENTITY(1,1) PRIMARY KEY,
        TenantId INT NOT NULL,
        AssetId INT,
        Title NVARCHAR(200) NOT NULL,
        Description NVARCHAR(MAX),
        Priority NVARCHAR(50) NOT NULL DEFAULT 'Medium', -- Low, Medium, High, Urgent
        Status NVARCHAR(50) NOT NULL DEFAULT 'Open', -- Open, InProgress, OnHold, Completed, Cancelled
        CreatedDate DATETIME NOT NULL DEFAULT GETDATE(),
        CreatedBy INT NOT NULL,
        AssignedTo NVARCHAR(200),
        CompletedDate DATETIME,
        CONSTRAINT FK_WorkOrders_Tenants FOREIGN KEY (TenantId) REFERENCES Tenants(TenantId),
        CONSTRAINT FK_WorkOrders_Assets FOREIGN KEY (AssetId) REFERENCES Assets(AssetId)
    );
END
GO
