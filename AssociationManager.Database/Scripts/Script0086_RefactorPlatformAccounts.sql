-- Script0086_RefactorPlatformAccounts.sql
-- Updating PlatformAccounts table to store Bank Details and updating Association List SP

-- 1. Ensure Associations table has the required columns for billing
IF NOT EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID('corp.Associations') AND name = 'PlatformAccountId')
BEGIN
    ALTER TABLE corp.Associations ADD [PlatformAccountId] INT NULL;
END
GO

IF NOT EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID('corp.Associations') AND name = 'AdminPaysFee')
BEGIN
    ALTER TABLE corp.Associations ADD [AdminPaysFee] BIT DEFAULT(1) NOT NULL;
END
GO

-- 2. Update PlatformAccounts Table
IF EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID('corp.PlatformAccounts') AND name = 'RazorpayKeyId')
BEGIN
    ALTER TABLE [corp].[PlatformAccounts] DROP COLUMN [RazorpayKeyId];
END
GO

IF EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID('corp.PlatformAccounts') AND name = 'RazorpayKeySecret')
BEGIN
    ALTER TABLE [corp].[PlatformAccounts] DROP COLUMN [RazorpayKeySecret];
END
GO

IF NOT EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID('corp.PlatformAccounts') AND name = 'AccountNumber')
BEGIN
    ALTER TABLE [corp].[PlatformAccounts] ADD [AccountNumber] NVARCHAR(50) NULL;
END
GO

IF NOT EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID('corp.PlatformAccounts') AND name = 'BankName')
BEGIN
    ALTER TABLE [corp].[PlatformAccounts] ADD [BankName] NVARCHAR(255) NULL;
END
GO

IF NOT EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID('corp.PlatformAccounts') AND name = 'IFSCCode')
BEGIN
    ALTER TABLE [corp].[PlatformAccounts] ADD [IFSCCode] NVARCHAR(20) NULL;
END
GO

IF NOT EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID('corp.PlatformAccounts') AND name = 'BranchName')
BEGIN
    ALTER TABLE [corp].[PlatformAccounts] ADD [BranchName] NVARCHAR(255) NULL;
END
GO

-- 2. Update PlatformAccounts Stored Procedures

CREATE OR ALTER PROCEDURE corp.sp_PlatformAccounts_Create 
    @AccountName NVARCHAR(100), 
    @AccountNumber NVARCHAR(50) = NULL,
    @BankName NVARCHAR(255) = NULL,
    @IFSCCode NVARCHAR(20) = NULL,
    @BranchName NVARCHAR(255) = NULL,
    @IsActive BIT 
AS 
BEGIN 
    INSERT INTO corp.PlatformAccounts (AccountName, AccountNumber, BankName, IFSCCode, BranchName, IsActive) 
    OUTPUT INSERTED.Id 
    VALUES (@AccountName, @AccountNumber, @BankName, @IFSCCode, @BranchName, @IsActive); 
END;
GO

CREATE OR ALTER PROCEDURE corp.sp_PlatformAccounts_Update 
    @Id INT,
    @AccountName NVARCHAR(100), 
    @AccountNumber NVARCHAR(50) = NULL,
    @BankName NVARCHAR(255) = NULL,
    @IFSCCode NVARCHAR(20) = NULL,
    @BranchName NVARCHAR(255) = NULL,
    @IsActive BIT 
AS 
BEGIN 
    UPDATE corp.PlatformAccounts 
    SET AccountName = @AccountName, 
        AccountNumber = @AccountNumber, 
        BankName = @BankName, 
        IFSCCode = @IFSCCode, 
        BranchName = @BranchName, 
        IsActive = @IsActive,
        LastUpdated = GETDATE()
    WHERE Id = @Id; 
END;
GO

-- 3. Update Associations List Stored Procedure to include Billing Account Name
CREATE OR ALTER PROCEDURE corp.sp_Associations_List
AS
BEGIN
    SELECT 
        a.*,
        pa.AccountName as BillingAccountName
    FROM corp.Associations a
    LEFT JOIN corp.PlatformAccounts pa ON a.PlatformAccountId = pa.Id;
END;
GO
