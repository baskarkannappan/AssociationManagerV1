-- Script0044_HighStrengthBilling.sql
-- Adds BillingBatches and InvoiceLineItems for high-integrity financial tracking

-- 1. Create BillingBatches Table
IF NOT EXISTS (SELECT * FROM sys.tables WHERE schema_id = SCHEMA_ID('assoc') AND name = 'BillingBatches')
BEGIN
    CREATE TABLE assoc.BillingBatches (
        BillingBatchId INT IDENTITY(1,1) PRIMARY KEY,
        TenantId INT NOT NULL,
        AssociationId INT NOT NULL,
        Month INT NOT NULL,
        Year INT NOT NULL,
        Status NVARCHAR(50) NOT NULL DEFAULT 'Committed',
        TotalAmount DECIMAL(18,2) NOT NULL DEFAULT 0,
        InvoicesGenerated INT NOT NULL DEFAULT 0,
        CreatedDate DATETIME NOT NULL DEFAULT GETDATE(),
        CONSTRAINT FK_BillingBatches_Tenants FOREIGN KEY (TenantId) REFERENCES corp.Tenants(TenantId),
        CONSTRAINT FK_BillingBatches_Associations FOREIGN KEY (AssociationId) REFERENCES corp.Associations(AssociationId)
    );
END
GO

-- 2. Add BillingBatchId to Invoices
IF NOT EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID('assoc.Invoices') AND name = 'BillingBatchId')
BEGIN
    ALTER TABLE assoc.Invoices ADD BillingBatchId INT NULL;
    ALTER TABLE assoc.Invoices ADD CONSTRAINT FK_Invoices_BillingBatches FOREIGN KEY (BillingBatchId) REFERENCES assoc.BillingBatches(BillingBatchId);
END
GO

-- 3. Create InvoiceLineItems Table
IF NOT EXISTS (SELECT * FROM sys.tables WHERE schema_id = SCHEMA_ID('assoc') AND name = 'InvoiceLineItems')
BEGIN
    CREATE TABLE assoc.InvoiceLineItems (
        InvoiceLineItemId INT IDENTITY(1,1) PRIMARY KEY,
        InvoiceId INT NOT NULL,
        ChargeName NVARCHAR(200) NOT NULL,
        Amount DECIMAL(18,2) NOT NULL,
        Description NVARCHAR(MAX) NULL,
        TariffLayerId INT NULL,
        Rate DECIMAL(18,2) NULL, -- Snapshot of rate at time of billing
        CONSTRAINT FK_InvoiceLineItems_Invoices FOREIGN KEY (InvoiceId) REFERENCES assoc.Invoices(InvoiceId) ON DELETE CASCADE
    );
END
GO

-- 4. Update Stored Procedures
PRINT 'Updating Stored Procedures for Billing Batches and Line Items...'
GO

CREATE OR ALTER PROCEDURE assoc.sp_BillingBatches_Create 
    @TenantId INT, 
    @AssociationId INT, 
    @Month INT, 
    @Year INT, 
    @Status NVARCHAR(50), 
    @TotalAmount DECIMAL(18,2), 
    @InvoicesGenerated INT, 
    @CreatedDate DATETIME 
AS 
BEGIN 
    INSERT INTO assoc.BillingBatches (TenantId, AssociationId, Month, Year, Status, TotalAmount, InvoicesGenerated, CreatedDate) 
    OUTPUT INSERTED.BillingBatchId 
    VALUES (@TenantId, @AssociationId, @Month, @Year, @Status, @TotalAmount, @InvoicesGenerated, @CreatedDate); 
END
GO

CREATE OR ALTER PROCEDURE assoc.sp_BillingBatches_GetById 
    @Id INT, 
    @TenantId INT, 
    @AssociationId INT 
AS 
BEGIN 
    SELECT * FROM assoc.BillingBatches WHERE BillingBatchId = @Id AND TenantId = @TenantId AND AssociationId = @AssociationId; 
END
GO

CREATE OR ALTER PROCEDURE assoc.sp_BillingBatches_GetByAssociation 
    @AssociationId INT, 
    @TenantId INT 
AS 
BEGIN 
    SELECT * FROM assoc.BillingBatches WHERE AssociationId = @AssociationId AND TenantId = @TenantId ORDER BY CreatedDate DESC; 
END
GO

CREATE OR ALTER PROCEDURE assoc.sp_InvoiceLineItems_Create 
    @InvoiceId INT, 
    @ChargeName NVARCHAR(200), 
    @Amount DECIMAL(18,2), 
    @Description NVARCHAR(MAX), 
    @TariffLayerId INT = NULL, 
    @Rate DECIMAL(18,2) = NULL 
AS 
BEGIN 
    INSERT INTO assoc.InvoiceLineItems (InvoiceId, ChargeName, Amount, Description, TariffLayerId, Rate) 
    OUTPUT INSERTED.InvoiceLineItemId 
    VALUES (@InvoiceId, @ChargeName, @Amount, @Description, @TariffLayerId, @Rate); 
END
GO

CREATE OR ALTER PROCEDURE assoc.sp_InvoiceLineItems_GetByInvoiceId 
    @InvoiceId INT 
AS 
BEGIN 
    SELECT * FROM assoc.InvoiceLineItems WHERE InvoiceId = @InvoiceId; 
END
GO

-- Update sp_Invoices_Create to include BillingBatchId
CREATE OR ALTER PROCEDURE assoc.sp_Invoices_Create 
    @TenantId INT, 
    @AssociationId INT, 
    @AssetId INT = NULL, 
    @BillingBatchId INT = NULL,
    @Title NVARCHAR(200), 
    @Description NVARCHAR(MAX) = NULL, 
    @Amount DECIMAL(18, 2), 
    @DueDate DATETIME, 
    @Status NVARCHAR(50), 
    @CreatedDate DATETIME 
AS 
BEGIN 
    INSERT INTO assoc.Invoices (TenantId, AssociationId, AssetId, BillingBatchId, Title, Description, Amount, DueDate, Status, CreatedDate) 
    OUTPUT INSERTED.InvoiceId 
    VALUES (@TenantId, @AssociationId, @AssetId, @BillingBatchId, @Title, @Description, @Amount, @DueDate, @Status, @CreatedDate); 
END
GO
