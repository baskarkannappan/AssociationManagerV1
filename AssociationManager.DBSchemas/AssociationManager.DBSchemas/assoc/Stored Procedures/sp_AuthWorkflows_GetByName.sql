CREATE   PROCEDURE assoc.sp_AuthWorkflows_GetByName
    @Name NVARCHAR(100)
AS
BEGIN
    SELECT WorkflowId, Name, WorkflowJson, Description, CreatedDate, UpdatedDate
    FROM assoc.AuthWorkflows
    WHERE Name = @Name;
END