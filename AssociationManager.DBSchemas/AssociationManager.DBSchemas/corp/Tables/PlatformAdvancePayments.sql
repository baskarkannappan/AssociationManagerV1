CREATE TABLE [corp].[PlatformAdvancePayments] (
    [PlatformAdvanceId] INT             IDENTITY (1, 1) NOT NULL,
    [AssociationId]     INT             NOT NULL,
    [Amount]            DECIMAL (18, 2) NOT NULL,
    [Date]              DATETIME        DEFAULT (getutcdate()) NOT NULL,
    [Status]            NVARCHAR (50)   DEFAULT ('Completed') NOT NULL,
    [TransactionRef]    NVARCHAR (255)  NULL,
    [Description]       NVARCHAR (500)  NULL,
    [Notes]             NVARCHAR (MAX)  NULL,
    [CreatedDate]       DATETIME        DEFAULT (getutcdate()) NOT NULL,
    PRIMARY KEY CLUSTERED ([PlatformAdvanceId] ASC),
    CONSTRAINT [FK_PlatformAdvancePayments_Association] FOREIGN KEY ([AssociationId]) REFERENCES [corp].[Associations] ([AssociationId])
);

