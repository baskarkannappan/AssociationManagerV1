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
