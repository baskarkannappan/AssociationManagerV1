-- Script0090_AddRazorpayToPlatformAccounts.sql
-- Add RazorpayKeyId and RazorpayKeySecret to corp.PlatformAccounts

IF NOT EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID('corp.PlatformAccounts') AND name = 'RazorpayKeyId')
BEGIN
    ALTER TABLE corp.PlatformAccounts ADD RazorpayKeyId NVARCHAR(255) NULL;
END

IF NOT EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID('corp.PlatformAccounts') AND name = 'RazorpayKeySecret')
BEGIN
    ALTER TABLE corp.PlatformAccounts ADD RazorpayKeySecret NVARCHAR(255) NULL;
END
GO

-- Update sp_PlatformAccounts_Create
ALTER PROCEDURE corp.sp_PlatformAccounts_Create
    @AccountName NVARCHAR(255),
    @AccountNumber NVARCHAR(50) = NULL,
    @BankName NVARCHAR(255) = NULL,
    @IFSCCode NVARCHAR(20) = NULL,
    @BranchName NVARCHAR(255) = NULL,
    @RazorpayKeyId NVARCHAR(255) = NULL,
    @RazorpayKeySecret NVARCHAR(255) = NULL
AS
BEGIN
    INSERT INTO corp.PlatformAccounts (AccountName, AccountNumber, BankName, IFSCCode, BranchName, RazorpayKeyId, RazorpayKeySecret, IsActive, LastUpdated)
    VALUES (@AccountName, @AccountNumber, @BankName, @IFSCCode, @BranchName, @RazorpayKeyId, @RazorpayKeySecret, 1, GETUTCDATE());
    SELECT SCOPE_IDENTITY();
END
GO

-- Update sp_PlatformAccounts_Update
ALTER PROCEDURE corp.sp_PlatformAccounts_Update
    @Id INT,
    @AccountName NVARCHAR(255),
    @AccountNumber NVARCHAR(50) = NULL,
    @BankName NVARCHAR(255) = NULL,
    @IFSCCode NVARCHAR(20) = NULL,
    @BranchName NVARCHAR(255) = NULL,
    @RazorpayKeyId NVARCHAR(255) = NULL,
    @RazorpayKeySecret NVARCHAR(255) = NULL,
    @IsActive BIT
AS
BEGIN
    UPDATE corp.PlatformAccounts
    SET AccountName = @AccountName,
        AccountNumber = @AccountNumber,
        BankName = @BankName,
        IFSCCode = @IFSCCode,
        BranchName = @BranchName,
        RazorpayKeyId = @RazorpayKeyId,
        RazorpayKeySecret = @RazorpayKeySecret,
        IsActive = @IsActive,
        LastUpdated = GETUTCDATE()
    WHERE Id = @Id;
END
GO
