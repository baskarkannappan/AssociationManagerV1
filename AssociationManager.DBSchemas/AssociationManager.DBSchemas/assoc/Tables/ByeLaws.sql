CREATE TABLE [assoc].[ByeLaws] (
    [ByeLawId]        INT             IDENTITY (1, 1) NOT NULL,
    [AssociationId]   INT             NOT NULL,
    [Title]           NVARCHAR (255)  NOT NULL,
    [Description]     NVARCHAR (MAX)  NULL,
    [EffectiveDate]   DATETIME        NOT NULL,
    [Version]         NVARCHAR (50)   NULL,
    [IsActive]        BIT             DEFAULT ((1)) NULL,
    [CreatedDate]     DATETIME        DEFAULT (getutcdate()) NULL,
    [DocumentContent] VARBINARY (MAX) NULL,
    [FileName]        NVARCHAR (255)  NULL,
    [ContentType]     NVARCHAR (100)  NULL,
    PRIMARY KEY CLUSTERED ([ByeLawId] ASC),
    FOREIGN KEY ([AssociationId]) REFERENCES [corp].[Associations] ([AssociationId])
);

