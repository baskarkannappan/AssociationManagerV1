CREATE TABLE [assoc].[Candidates] (
    [CandidateId] INT IDENTITY (1, 1) NOT NULL,
    [ElectionId]  INT NOT NULL,
    [MemberId]    INT NOT NULL,
    PRIMARY KEY CLUSTERED ([CandidateId] ASC),
    FOREIGN KEY ([ElectionId]) REFERENCES [assoc].[Elections] ([ElectionId]),
    FOREIGN KEY ([MemberId]) REFERENCES [corp].[Users] ([UserId])
);

