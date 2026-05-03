
CREATE   PROCEDURE [assoc].[sp_CommunicationLogs_UpdateStatus]
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