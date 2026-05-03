-- CREATE TABLE
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[assoc].[CommunicationLogs]') AND type in (N'U'))
BEGIN
    CREATE TABLE [assoc].[CommunicationLogs] (
        [LogId] INT IDENTITY(1,1) PRIMARY KEY,
        [TenantId] INT NOT NULL,
        [AssociationId] INT NOT NULL,
        [RecipientEmail] NVARCHAR(255) NOT NULL,
        [RecipientName] NVARCHAR(255) NULL,
        [Subject] NVARCHAR(500) NOT NULL,
        [HtmlBody] NVARCHAR(MAX) NOT NULL,
        [ReferenceType] NVARCHAR(50) NULL,
        [ReferenceId] INT NULL,
        [Status] INT NOT NULL DEFAULT 1, -- 1 = Posted
        [ErrorMessage] NVARCHAR(MAX) NULL,
        [RetryCount] INT NOT NULL DEFAULT 0,
        [CreatedDate] DATETIME2 NOT NULL DEFAULT GETUTCDATE(),
        [ProcessedDate] DATETIME2 NULL,
        [ScheduledDate] DATETIME2 NULL
    );
    
    CREATE INDEX IX_CommunicationLogs_Tenant_Assoc ON [assoc].[CommunicationLogs] (TenantId, AssociationId);
    CREATE INDEX IX_CommunicationLogs_Status ON [assoc].[CommunicationLogs] ([Status]);
END
GO

-- STORED PROCEDURES

CREATE OR ALTER PROCEDURE [assoc].[sp_CommunicationLogs_GetById]
    @Id INT,
    @TenantId INT,
    @AssociationId INT
AS
BEGIN
    SELECT * FROM [assoc].[CommunicationLogs]
    WHERE LogId = @Id AND TenantId = @TenantId AND AssociationId = @AssociationId;
END
GO

CREATE OR ALTER PROCEDURE [assoc].[sp_CommunicationLogs_GetByAssociation]
    @TenantId INT,
    @AssociationId INT,
    @Status INT = NULL
AS
BEGIN
    SELECT * FROM [assoc].[CommunicationLogs]
    WHERE TenantId = @TenantId 
      AND AssociationId = @AssociationId
      AND (@Status IS NULL OR Status = @Status)
    ORDER BY CreatedDate DESC;
END
GO

CREATE OR ALTER PROCEDURE [assoc].[sp_CommunicationLogs_GetPending]
AS
BEGIN
    SELECT * FROM [assoc].[CommunicationLogs]
    WHERE Status IN (1, 7) -- Posted OR Resend
      AND (ScheduledDate IS NULL OR ScheduledDate <= GETUTCDATE())
    ORDER BY CreatedDate ASC;
END
GO

CREATE OR ALTER PROCEDURE [assoc].[sp_CommunicationLogs_Create]
    @TenantId INT,
    @AssociationId INT,
    @RecipientEmail NVARCHAR(255),
    @RecipientName NVARCHAR(255) = NULL,
    @Subject NVARCHAR(500),
    @HtmlBody NVARCHAR(MAX),
    @ReferenceType NVARCHAR(50) = NULL,
    @ReferenceId INT = NULL,
    @Status INT = 1,
    @ScheduledDate DATETIME2 = NULL
AS
BEGIN
    INSERT INTO [assoc].[CommunicationLogs] (
        TenantId, AssociationId, RecipientEmail, RecipientName, Subject, HtmlBody, 
        ReferenceType, ReferenceId, Status, ScheduledDate, CreatedDate
    )
    VALUES (
        @TenantId, @AssociationId, @RecipientEmail, @RecipientName, @Subject, @HtmlBody, 
        @ReferenceType, @ReferenceId, @Status, @ScheduledDate, GETUTCDATE()
    );
    
    SELECT SCOPE_IDENTITY();
END
GO

CREATE OR ALTER PROCEDURE [assoc].[sp_CommunicationLogs_UpdateStatus]
    @Id INT,
    @TenantId INT,
    @Status INT,
    @ErrorMessage NVARCHAR(MAX) = NULL
AS
BEGIN
    UPDATE [assoc].[CommunicationLogs]
    SET Status = @Status,
        ErrorMessage = @ErrorMessage,
        ProcessedDate = CASE WHEN @Status IN (4, 5, 6) THEN GETUTCDATE() ELSE ProcessedDate END,
        RetryCount = CASE WHEN @Status = 5 THEN RetryCount + 1 ELSE RetryCount END
    WHERE LogId = @Id AND TenantId = @TenantId;
END
GO
