CREATE TABLE [assoc].[AuthWorkflows] (
    [WorkflowId]   INT            IDENTITY (1, 1) NOT NULL,
    [Name]         NVARCHAR (100) NOT NULL,
    [WorkflowJson] NVARCHAR (MAX) NOT NULL,
    [Description]  NVARCHAR (255) NULL,
    [CreatedDate]  DATETIME2 (7)  DEFAULT (getutcdate()) NOT NULL,
    [UpdatedDate]  DATETIME2 (7)  DEFAULT (getutcdate()) NOT NULL,
    PRIMARY KEY CLUSTERED ([WorkflowId] ASC),
    UNIQUE NONCLUSTERED ([Name] ASC)
);

