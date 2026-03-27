-- Rule Engine Schema
IF NOT EXISTS (SELECT * FROM sys.schemas WHERE name = 'assoc')
BEGIN
    EXEC('CREATE SCHEMA assoc')
END

IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'AuthWorkflows' AND schema_id = SCHEMA_ID('assoc'))
BEGIN
    CREATE TABLE assoc.AuthWorkflows (
        WorkflowId INT PRIMARY KEY IDENTITY(1,1),
        Name NVARCHAR(100) NOT NULL UNIQUE,
        WorkflowJson NVARCHAR(MAX) NOT NULL,
        Description NVARCHAR(255),
        CreatedDate DATETIME2 NOT NULL DEFAULT GETUTCDATE(),
        UpdatedDate DATETIME2 NOT NULL DEFAULT GETUTCDATE()
    );
END

GO

CREATE OR ALTER PROCEDURE assoc.sp_AuthWorkflows_GetByName
    @Name NVARCHAR(100)
AS
BEGIN
    SELECT WorkflowId, Name, WorkflowJson, Description, CreatedDate, UpdatedDate
    FROM assoc.AuthWorkflows
    WHERE Name = @Name;
END

GO

CREATE OR ALTER PROCEDURE assoc.sp_AuthWorkflows_Upsert
    @Name NVARCHAR(100),
    @WorkflowJson NVARCHAR(MAX),
    @Description NVARCHAR(255) = NULL
AS
BEGIN
    IF EXISTS (SELECT 1 FROM assoc.AuthWorkflows WHERE Name = @Name)
    BEGIN
        UPDATE assoc.AuthWorkflows
        SET WorkflowJson = @WorkflowJson,
            Description = ISNULL(@Description, Description),
            UpdatedDate = GETUTCDATE()
        WHERE Name = @Name;
    END
    ELSE
    BEGIN
        INSERT INTO assoc.AuthWorkflows (Name, WorkflowJson, Description)
        VALUES (@Name, @WorkflowJson, @Description);
    END
END
