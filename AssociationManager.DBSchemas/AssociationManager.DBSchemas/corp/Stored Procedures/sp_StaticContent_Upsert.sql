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
