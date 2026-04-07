-- Script0085_PlatformAccounts.sql
-- Create PlatformAccounts table and associated stored procedures

-- 1. Table
IF NOT EXISTS (SELECT * FROM sys.tables WHERE schema_id = SCHEMA_ID('corp') AND name = 'PlatformAccounts')
BEGIN
    CREATE TABLE [corp].[PlatformAccounts] (
        [Id]                INT            IDENTITY (1, 1) NOT NULL,
        [AccountName]       NVARCHAR (100) NOT NULL,
        [RazorpayKeyId]     NVARCHAR (100) NOT NULL,
        [RazorpayKeySecret] NVARCHAR (100) NULL,
        [IsActive]          BIT            DEFAULT (1) NOT NULL,
        [LastUpdated]       DATETIME       DEFAULT (GETDATE()) NOT NULL,
        PRIMARY KEY CLUSTERED ([Id] ASC)
    );
END
GO

-- 2. Stored Procedures

CREATE OR ALTER PROCEDURE corp.sp_PlatformAccounts_GetById 
    @Id INT 
AS 
BEGIN 
    SELECT * FROM corp.PlatformAccounts WHERE Id = @Id; 
END;
GO

CREATE OR ALTER PROCEDURE corp.sp_PlatformAccounts_List 
AS 
BEGIN 
    SELECT * FROM corp.PlatformAccounts; 
END;
GO

CREATE OR ALTER PROCEDURE corp.sp_PlatformAccounts_Create 
    @AccountName NVARCHAR(100), 
    @RazorpayKeyId NVARCHAR(100), 
    @RazorpayKeySecret NVARCHAR(100), 
    @IsActive BIT 
AS 
BEGIN 
    INSERT INTO corp.PlatformAccounts (AccountName, RazorpayKeyId, RazorpayKeySecret, IsActive) 
    OUTPUT INSERTED.Id 
    VALUES (@AccountName, @RazorpayKeyId, @RazorpayKeySecret, @IsActive); 
END;
GO

CREATE OR ALTER PROCEDURE corp.sp_PlatformAccounts_Update 
    @Id INT,
    @AccountName NVARCHAR(100), 
    @RazorpayKeyId NVARCHAR(100), 
    @RazorpayKeySecret NVARCHAR(100), 
    @IsActive BIT 
As 
BEGIN 
    UPDATE corp.PlatformAccounts 
    SET AccountName = @AccountName, 
        RazorpayKeyId = @RazorpayKeyId, 
        RazorpayKeySecret = @RazorpayKeySecret, 
        IsActive = @IsActive,
        LastUpdated = GETDATE()
    WHERE Id = @Id; 
END;
GO

CREATE OR ALTER PROCEDURE corp.sp_PlatformAccounts_Delete 
    @Id INT 
AS 
BEGIN 
    DELETE FROM corp.PlatformAccounts WHERE Id = @Id; 
END;
GO
