CREATE   PROCEDURE corp.sp_PlatformAccounts_GetById @Id INT AS 
BEGIN SELECT * FROM corp.PlatformAccounts WHERE Id = @Id; END
GO

CREATE   PROCEDURE corp.sp_PlatformAccounts_List AS 
BEGIN SELECT * FROM corp.PlatformAccounts; END
GO

CREATE   PROCEDURE corp.sp_PlatformAccounts_Create 
    @AccountName NVARCHAR(100), 
    @RazorpayKeyId NVARCHAR(100), 
    @RazorpayKeySecret NVARCHAR(100), 
    @IsActive BIT 
AS 
BEGIN 
    INSERT INTO corp.PlatformAccounts (AccountName, RazorpayKeyId, RazorpayKeySecret, IsActive) 
    OUTPUT INSERTED.Id 
    VALUES (@AccountName, @RazorpayKeyId, @RazorpayKeySecret, @IsActive); 
END
GO

CREATE   PROCEDURE corp.sp_PlatformAccounts_Update 
    @Id INT,
    @AccountName NVARCHAR(100), 
    @RazorpayKeyId NVARCHAR(100), 
    @RazorpayKeySecret NVARCHAR(100), 
    @IsActive BIT 
AS 
BEGIN 
    UPDATE corp.PlatformAccounts 
    SET AccountName = @AccountName, 
        RazorpayKeyId = @RazorpayKeyId, 
        RazorpayKeySecret = @RazorpayKeySecret, 
        IsActive = @IsActive 
    WHERE Id = @Id; 
END
GO

CREATE   PROCEDURE corp.sp_PlatformAccounts_Delete @Id INT AS 
BEGIN DELETE FROM corp.PlatformAccounts WHERE Id = @Id; END
GO
