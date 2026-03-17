USE AssociationManagerV1;
GO

-- Invoices Table
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'Invoices')
BEGIN
    CREATE TABLE Invoices (
        InvoiceId INT IDENTITY(1,1) PRIMARY KEY,
        TenantId INT NOT NULL,
        AssetId INT, -- Optional: Link to a specific Unit/Property
        Title NVARCHAR(200) NOT NULL,
        Description NVARCHAR(500),
        Amount DECIMAL(18,2) NOT NULL,
        DueDate DATETIME NOT NULL,
        Status NVARCHAR(50) NOT NULL DEFAULT 'Unpaid', -- Unpaid, Partial, Paid, Cancelled
        CreatedDate DATETIME NOT NULL DEFAULT GETDATE(),
        CONSTRAINT FK_Invoices_Tenants FOREIGN KEY (TenantId) REFERENCES Tenants(TenantId),
        CONSTRAINT FK_Invoices_Assets FOREIGN KEY (AssetId) REFERENCES Assets(AssetId)
    );
END
GO

-- Update Payments Table to link to Invoices
IF NOT EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID('Payments') AND name = 'InvoiceId')
BEGIN
    ALTER TABLE Payments ADD InvoiceId INT;
    ALTER TABLE Payments ADD CONSTRAINT FK_Payments_Invoices FOREIGN KEY (InvoiceId) REFERENCES Invoices(InvoiceId);
END
GO
