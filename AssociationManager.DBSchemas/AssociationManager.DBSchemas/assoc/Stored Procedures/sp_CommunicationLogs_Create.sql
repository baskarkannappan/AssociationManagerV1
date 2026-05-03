
CREATE   PROCEDURE [assoc].[sp_CommunicationLogs_Create]
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