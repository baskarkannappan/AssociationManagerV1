CREATE TABLE [assoc].[MeetingMinutes] (
    [MinutesId]   INT            IDENTITY (1, 1) NOT NULL,
    [MeetingId]   INT            NOT NULL,
    [Notes]       NVARCHAR (MAX) NULL,
    [DocumentUrl] NVARCHAR (MAX) NULL,
    [CreatedDate] DATETIME       DEFAULT (getutcdate()) NULL,
    PRIMARY KEY CLUSTERED ([MinutesId] ASC),
    FOREIGN KEY ([MeetingId]) REFERENCES [assoc].[Meetings] ([MeetingId])
);

