CREATE TABLE [corp].[StaticContent]
(
    [ContentKey] NVARCHAR(50) NOT NULL PRIMARY KEY,
    [Title] NVARCHAR(200) NOT NULL,
    [HtmlContent] NVARCHAR(MAX) NOT NULL,
    [LastUpdated] DATETIME NOT NULL DEFAULT GETUTCDATE(),
    [UpdatedBy] INT NULL
)
GO
