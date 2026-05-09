CREATE   PROCEDURE assoc.sp_AuthWorkflows_Upsert
    @Name NVARCHAR(100),
    @WorkflowJson NVARCHAR(MAX),
    @Description NVARCHAR(255) = NULL
AS
BEGIN
    IF EXISTS (SELECT 1 FROM assoc.AuthWorkflows WHERE Name = @Name)
    BEGIN
        -- PERFORMANCE: Only update if the content has actually changed to avoid unnecessary writes and index maintenance
        IF EXISTS (
            SELECT 1 FROM assoc.AuthWorkflows 
            WHERE Name = @Name 
              AND (WorkflowJson <> @WorkflowJson OR ISNULL(Description, '') <> ISNULL(@Description, ISNULL(Description, '')))
        )
        BEGIN
            UPDATE assoc.AuthWorkflows
            SET WorkflowJson = @WorkflowJson,
                Description = ISNULL(@Description, Description),
                UpdatedDate = GETUTCDATE()
            WHERE Name = @Name;
        END
    END
    ELSE
    BEGIN
        INSERT INTO assoc.AuthWorkflows (Name, WorkflowJson, Description)
        VALUES (@Name, @WorkflowJson, @Description);
    END
END