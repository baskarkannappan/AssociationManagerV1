-- Update sp_PlatformAccounts_Create
CREATE PROCEDURE corp.sp_PlatformAccounts_Create
    @AccountName NVARCHAR(255),
    @AccountNumber NVARCHAR(50) = NULL,
    @BankName NVARCHAR(255) = NULL,
    @IFSCCode NVARCHAR(20) = NULL,
    @BranchName NVARCHAR(255) = NULL,
    @RazorpayKeyId NVARCHAR(255) = NULL,
    @RazorpayKeySecret NVARCHAR(255) = NULL,
    @IsActive BIT = 1
AS
BEGIN
    INSERT INTO corp.PlatformAccounts (AccountName, AccountNumber, BankName, IFSCCode, BranchName, RazorpayKeyId, RazorpayKeySecret, IsActive, LastUpdated)
    VALUES (@AccountName, @AccountNumber, @BankName, @IFSCCode, @BranchName, @RazorpayKeyId, @RazorpayKeySecret, @IsActive, GETUTCDATE());
    SELECT SCOPE_IDENTITY();
END