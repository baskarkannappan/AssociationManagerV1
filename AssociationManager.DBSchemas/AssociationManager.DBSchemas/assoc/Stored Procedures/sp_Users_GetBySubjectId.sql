CREATE PROCEDURE assoc.sp_Users_GetBySubjectId
    @SubjectId NVARCHAR(255)
AS
BEGIN
    SET NOCOUNT ON;
    SELECT * FROM assoc.Users WHERE SubjectId = @SubjectId;
END
GO
