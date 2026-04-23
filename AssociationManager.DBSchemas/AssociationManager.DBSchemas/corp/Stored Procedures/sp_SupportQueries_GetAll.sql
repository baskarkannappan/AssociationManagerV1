CREATE PROCEDURE [corp].[sp_SupportQueries_GetAll]
AS
BEGIN
    SET NOCOUNT ON;
    
    SELECT [QueryId], [UserId], [Name], [Email], [Subject], [MessageBody], [Status], [CreatedDate]
    FROM [corp].[SupportQueries]
    ORDER BY [CreatedDate] DESC;
END
GO
