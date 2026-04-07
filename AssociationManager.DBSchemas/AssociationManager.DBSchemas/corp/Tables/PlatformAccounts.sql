CREATE TABLE [corp].[PlatformAccounts] (
    [Id]                INT            IDENTITY (1, 1) NOT NULL,
    [AccountName]       NVARCHAR (100) NOT NULL,
    [RazorpayKeyId]     NVARCHAR (100) NOT NULL,
    [RazorpayKeySecret] NVARCHAR (100) NULL,
    [IsActive]          BIT            DEFAULT (1) NOT NULL,
    [LastUpdated]       DATETIME       DEFAULT (getdate()) NOT NULL,
    PRIMARY KEY CLUSTERED ([Id] ASC)
);
