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
