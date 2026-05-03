-- Create StaticContent Table
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'StaticContent' AND schema_id = SCHEMA_ID('corp'))
BEGIN
    CREATE TABLE [corp].[StaticContent]
    (
        [ContentKey] NVARCHAR(50) NOT NULL PRIMARY KEY,
        [Title] NVARCHAR(200) NOT NULL,
        [HtmlContent] NVARCHAR(MAX) NOT NULL,
        [LastUpdated] DATETIME NOT NULL DEFAULT GETUTCDATE(),
        [UpdatedBy] INT NULL
    );
END
GO

-- Create SupportQueries Table
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'SupportQueries' AND schema_id = SCHEMA_ID('corp'))
BEGIN
    CREATE TABLE [corp].[SupportQueries]
    (
        [QueryId] INT IDENTITY(1,1) PRIMARY KEY,
        [UserId] INT NULL,
        [Name] NVARCHAR(100) NOT NULL,
        [Email] NVARCHAR(100) NOT NULL,
        [Subject] NVARCHAR(200) NOT NULL,
        [MessageBody] NVARCHAR(MAX) NOT NULL,
        [Status] NVARCHAR(50) NOT NULL DEFAULT 'New',
        [CreatedDate] DATETIME NOT NULL DEFAULT GETUTCDATE()
    );
END
GO

-- Stored Procedures
IF EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[corp].[sp_StaticContent_GetByKey]') AND type in (N'P', N'PC'))
    DROP PROCEDURE [corp].[sp_StaticContent_GetByKey]
GO
CREATE PROCEDURE [corp].[sp_StaticContent_GetByKey]
    @ContentKey NVARCHAR(50)
AS
BEGIN
    SET NOCOUNT ON;
    SELECT [ContentKey], [Title], [HtmlContent], [LastUpdated], [UpdatedBy]
    FROM [corp].[StaticContent]
    WHERE [ContentKey] = @ContentKey;
END
GO

IF EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[corp].[sp_StaticContent_Upsert]') AND type in (N'P', N'PC'))
    DROP PROCEDURE [corp].[sp_StaticContent_Upsert]
GO
CREATE PROCEDURE [corp].[sp_StaticContent_Upsert]
    @ContentKey NVARCHAR(50),
    @Title NVARCHAR(200),
    @HtmlContent NVARCHAR(MAX),
    @UpdatedBy INT
AS
BEGIN
    SET NOCOUNT ON;
    
    IF EXISTS (SELECT 1 FROM [corp].[StaticContent] WHERE [ContentKey] = @ContentKey)
    BEGIN
        UPDATE [corp].[StaticContent]
        SET [Title] = @Title,
            [HtmlContent] = @HtmlContent,
            [LastUpdated] = GETUTCDATE(),
            [UpdatedBy] = @UpdatedBy
        WHERE [ContentKey] = @ContentKey;
    END
    ELSE
    BEGIN
        INSERT INTO [corp].[StaticContent] ([ContentKey], [Title], [HtmlContent], [LastUpdated], [UpdatedBy])
        VALUES (@ContentKey, @Title, @HtmlContent, GETUTCDATE(), @UpdatedBy);
    END
END
GO

IF EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[corp].[sp_SupportQueries_Create]') AND type in (N'P', N'PC'))
    DROP PROCEDURE [corp].[sp_SupportQueries_Create]
GO
CREATE PROCEDURE [corp].[sp_SupportQueries_Create]
    @UserId INT = NULL,
    @Name NVARCHAR(100),
    @Email NVARCHAR(100),
    @Subject NVARCHAR(200),
    @MessageBody NVARCHAR(MAX)
AS
BEGIN
    SET NOCOUNT ON;
    
    INSERT INTO [corp].[SupportQueries] ([UserId], [Name], [Email], [Subject], [MessageBody], [Status], [CreatedDate])
    VALUES (@UserId, @Name, @Email, @Subject, @MessageBody, 'New', GETUTCDATE());
    
    SELECT SCOPE_IDENTITY();
END
GO

IF EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[corp].[sp_SupportQueries_GetAll]') AND type in (N'P', N'PC'))
    DROP PROCEDURE [corp].[sp_SupportQueries_GetAll]
GO
CREATE PROCEDURE [corp].[sp_SupportQueries_GetAll]
AS
BEGIN
    SET NOCOUNT ON;
    
    SELECT [QueryId], [UserId], [Name], [Email], [Subject], [MessageBody], [Status], [CreatedDate]
    FROM [corp].[SupportQueries]
    ORDER BY [CreatedDate] DESC;
END
GO

-- Seed Initial Content
IF NOT EXISTS (SELECT 1 FROM [corp].[StaticContent] WHERE [ContentKey] = 'about-us')
BEGIN
    INSERT INTO [corp].[StaticContent] ([ContentKey], [Title], [HtmlContent], [LastUpdated])
    VALUES ('about-us', 'About Association Manager', '<h2>Welcome to Association Manager</h2><p>Our platform provides a comprehensive suite of tools for managing residential and commercial associations. We simplify billing, communication, and governance.</p>', GETUTCDATE());
END

IF NOT EXISTS (SELECT 1 FROM [corp].[StaticContent] WHERE [ContentKey] = 'contact-us-details')
BEGIN
    INSERT INTO [corp].[StaticContent] ([ContentKey], [Title], [HtmlContent], [LastUpdated])
    VALUES ('contact-us-details', 'Contact Information', '<p><strong>Headquarters:</strong><br/>123 Innovation Drive<br/>Tech City, TC 56789</p><p><strong>Support:</strong> support@assocmgr.com</p>', GETUTCDATE());
END

IF NOT EXISTS (SELECT 1 FROM [corp].[StaticContent] WHERE [ContentKey] = 'rules-regulations')
BEGIN
    INSERT INTO [corp].[StaticContent] ([ContentKey], [Title], [HtmlContent], [LastUpdated])
    VALUES ('rules-regulations', 'Rules & Regulations', '<h2>Standard Operating Procedures</h2><p>Please refer to your specific association''s bye-laws for detailed rules. General platform usage rules include:</p><ul><li>Ensure timely payment of dues.</li><li>Keep contact information up to date.</li><li>Respect community privacy.</li></ul>', GETUTCDATE());
END
GO
