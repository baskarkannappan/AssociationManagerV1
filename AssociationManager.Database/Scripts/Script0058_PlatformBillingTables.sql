-- Platform Billing Database Schema (Corporate DB)

-- 1. Invoices for charging Associations
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'PlatformInvoices' AND schema_id = SCHEMA_ID('corp'))
BEGIN
    CREATE TABLE corp.PlatformInvoices (
        PlatformInvoiceId INT PRIMARY KEY IDENTITY(1,1),
        AssociationId INT NOT NULL,
        PlanId INT NOT NULL,
        Amount DECIMAL(18,2) NOT NULL,
        BillingDate DATETIME NOT NULL DEFAULT GETUTCDATE(),
        DueDate DATETIME NOT NULL,
        Status NVARCHAR(50) NOT NULL DEFAULT 'Unpaid', -- Unpaid, Paid, Overdue, Cancelled
        CreatedDate DATETIME NOT NULL DEFAULT GETUTCDATE(),
        
        CONSTRAINT FK_PlatformInvoices_Association FOREIGN KEY (AssociationId) REFERENCES corp.Associations(AssociationId),
        CONSTRAINT FK_PlatformInvoices_Plan FOREIGN KEY (PlanId) REFERENCES corp.SubscriptionPlans(PlanId)
    );
END
GO

-- 2. Payments from Associations
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'PlatformPayments' AND schema_id = SCHEMA_ID('corp'))
BEGIN
    CREATE TABLE corp.PlatformPayments (
        PlatformPaymentId INT PRIMARY KEY IDENTITY(1,1),
        PlatformInvoiceId INT NOT NULL,
        Amount DECIMAL(18,2) NOT NULL,
        PaymentDate DATETIME NOT NULL DEFAULT GETUTCDATE(),
        TransactionRef NVARCHAR(255) NULL,
        
        CONSTRAINT FK_PlatformPayments_Invoice FOREIGN KEY (PlatformInvoiceId) REFERENCES corp.PlatformInvoices(PlatformInvoiceId)
    );
END
GO

-- 3. Stored Procedures

CREATE OR ALTER PROCEDURE corp.sp_PlatformInvoices_Insert
    @AssociationId INT,
    @PlanId INT,
    @Amount DECIMAL(18,2),
    @DueDate DATETIME
AS
BEGIN
    INSERT INTO corp.PlatformInvoices (AssociationId, PlanId, Amount, DueDate)
    VALUES (@AssociationId, @PlanId, @Amount, @DueDate);
    SELECT SCOPE_IDENTITY();
END;
GO

CREATE OR ALTER PROCEDURE corp.sp_PlatformInvoices_GetByAssociationId
    @AssociationId INT
AS
BEGIN
    SELECT pi.*, sp.Name as PlanName
    FROM corp.PlatformInvoices pi
    JOIN corp.SubscriptionPlans sp ON pi.PlanId = sp.PlanId
    WHERE pi.AssociationId = @AssociationId
    ORDER BY pi.BillingDate DESC;
END;
GO

CREATE OR ALTER PROCEDURE corp.sp_PlatformPayments_Insert
    @PlatformInvoiceId INT,
    @Amount DECIMAL(18,2),
    @TransactionRef NVARCHAR(255)
AS
BEGIN
    BEGIN TRANSACTION;
    
    INSERT INTO corp.PlatformPayments (PlatformInvoiceId, Amount, TransactionRef)
    VALUES (@PlatformInvoiceId, @Amount, @TransactionRef);
    
    UPDATE corp.PlatformInvoices 
    SET Status = 'Paid' 
    WHERE PlatformInvoiceId = @PlatformInvoiceId;
    
    COMMIT TRANSACTION;
    SELECT SCOPE_IDENTITY();
END;
GO
