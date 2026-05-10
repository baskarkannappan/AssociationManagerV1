CREATE PROCEDURE corp.sp_Users_GetBySubjectId
    @SubjectId NVARCHAR(255)
AS
BEGIN
    SET NOCOUNT ON;
    SELECT * FROM corp.Users WHERE SubjectId = @SubjectId;
END
GO
