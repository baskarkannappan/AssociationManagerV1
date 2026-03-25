CREATE TABLE [assoc].[Meetings] (
    [MeetingId]     INT            IDENTITY (1, 1) NOT NULL,
    [AssociationId] INT            NOT NULL,
    [Title]         NVARCHAR (255) NOT NULL,
    [MeetingDate]   DATETIME       NOT NULL,
    [Description]   NVARCHAR (MAX) NULL,
    [CreatedBy]     INT            NOT NULL,
    [CreatedDate]   DATETIME       DEFAULT (getutcdate()) NULL,
    PRIMARY KEY CLUSTERED ([MeetingId] ASC),
    FOREIGN KEY ([AssociationId]) REFERENCES [corp].[Associations] ([AssociationId]),
    FOREIGN KEY ([CreatedBy]) REFERENCES [corp].[Users] ([UserId])
);

