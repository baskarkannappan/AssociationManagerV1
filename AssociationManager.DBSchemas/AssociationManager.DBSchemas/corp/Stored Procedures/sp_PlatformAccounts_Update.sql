-- Update sp_PlatformAccounts_Update
CREATE PROCEDURE corp.sp_PlatformAccounts_Update
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