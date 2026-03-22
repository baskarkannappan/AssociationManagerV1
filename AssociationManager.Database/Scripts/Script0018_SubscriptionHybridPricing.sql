/*
    Script 0018: Subscription Hybrid Pricing
    Initializes the Subscription Plans and Association Subscriptions tables.
*/

GO
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'SubscriptionPlans')
BEGIN
    CREATE TABLE SubscriptionPlans (
        PlanId INT IDENTITY(1,1) PRIMARY KEY,
        Name NVARCHAR(100) NOT NULL,
        BasePrice DECIMAL(18,2) NOT NULL DEFAULT 0,
        PricePerAsset DECIMAL(18,2) NOT NULL DEFAULT 0,
        IsActive BIT NOT NULL DEFAULT 1
    );
END
GO

IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'AssociationSubscriptions')
BEGIN
    CREATE TABLE AssociationSubscriptions (
        SubscriptionId INT IDENTITY(1,1) PRIMARY KEY,
        AssociationId INT NOT NULL,
        PlanId INT NOT NULL,
        Status NVARCHAR(50) NOT NULL DEFAULT 'Active', -- Active, Cancelled, PastDue
        StartDate DATETIME NOT NULL DEFAULT GETDATE(),
        NextBillingDate DATETIME NOT NULL,
        CONSTRAINT FK_AssociationSubscriptions_Associations FOREIGN KEY (AssociationId) REFERENCES Associations(AssociationId),
        CONSTRAINT FK_AssociationSubscriptions_Plans FOREIGN KEY (PlanId) REFERENCES SubscriptionPlans(PlanId)
    );
END
GO

-- Seed Plans
IF NOT EXISTS (SELECT * FROM SubscriptionPlans WHERE Name = 'Starter')
BEGIN
    INSERT INTO SubscriptionPlans (Name, BasePrice, PricePerAsset) VALUES ('Starter', 50.00, 0.50);
    INSERT INTO SubscriptionPlans (Name, BasePrice, PricePerAsset) VALUES ('Pro', 150.00, 0.30);
    INSERT INTO SubscriptionPlans (Name, BasePrice, PricePerAsset) VALUES ('Enterprise', 500.00, 0.20);
END
GO

-- Stored Procedures
CREATE OR ALTER PROCEDURE sp_Subscriptions_GetByAssociationId
    @AssociationId INT
AS
BEGIN
    SELECT s.*, a.TenantId, p.Name as PlanName, p.BasePrice, p.PricePerAsset
    FROM AssociationSubscriptions s
    JOIN SubscriptionPlans p ON s.PlanId = p.PlanId
    JOIN Associations a ON s.AssociationId = a.AssociationId
    WHERE s.AssociationId = @AssociationId;
END
GO

CREATE OR ALTER PROCEDURE sp_SubscriptionPlans_GetAll
AS
BEGIN
    SELECT * FROM SubscriptionPlans WHERE IsActive = 1;
END
GO

CREATE OR ALTER PROCEDURE corp.sp_Subscriptions_Upsert
    @AssociationId INT,
    @PlanId INT,
    @Status NVARCHAR(50),
    @NextBillingDate DATETIME
AS
BEGIN
    IF EXISTS (SELECT 1 FROM AssociationSubscriptions WHERE AssociationId = @AssociationId)
    BEGIN
        UPDATE AssociationSubscriptions
        SET PlanId = @PlanId, Status = @Status, NextBillingDate = @NextBillingDate
        WHERE AssociationId = @AssociationId;
    END
    ELSE
    BEGIN
        INSERT INTO AssociationSubscriptions (AssociationId, PlanId, Status, NextBillingDate)
        VALUES (@AssociationId, @PlanId, @Status, @NextBillingDate);
    END
END
GO
