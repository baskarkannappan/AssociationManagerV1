CREATE TABLE [corp].[PlatformAccounts] (
    [Id]                INT            IDENTITY (1, 1) NOT NULL,
    [AccountName]       NVARCHAR (100) NOT NULL,
    [IsActive]          BIT            DEFAULT ((1)) NOT NULL,
    [LastUpdated]       DATETIME       DEFAULT (getdate()) NOT NULL,
    [AccountNumber]     NVARCHAR (50)  NULL,
    [BankName]          NVARCHAR (255) NULL,
    [IFSCCode]          NVARCHAR (20)  NULL,
    [BranchName]        NVARCHAR (255) NULL,
    [RazorpayKeyId]     NVARCHAR (255) NULL,
    [RazorpayKeySecret] NVARCHAR (255) NULL,
    PRIMARY KEY CLUSTERED ([Id] ASC)
);

