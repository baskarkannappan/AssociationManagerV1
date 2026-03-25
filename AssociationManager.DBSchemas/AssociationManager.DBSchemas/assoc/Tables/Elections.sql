CREATE TABLE [assoc].[Elections] (
    [ElectionId]    INT            IDENTITY (1, 1) NOT NULL,
    [AssociationId] INT            NOT NULL,
    [Title]         NVARCHAR (255) NOT NULL,
    [StartDate]     DATETIME       NOT NULL,
    [EndDate]       DATETIME       NOT NULL,
    [IsActive]      BIT            DEFAULT ((1)) NULL,
    PRIMARY KEY CLUSTERED ([ElectionId] ASC),
    FOREIGN KEY ([AssociationId]) REFERENCES [corp].[Associations] ([AssociationId])
);

