
CREATE   PROCEDURE [assoc].[sp_CommunicationLogs_GetPending]
AS
BEGIN
    SELECT * FROM [assoc].[CommunicationLogs]
    WHERE Status IN (1, 7) -- Posted OR Resend
      AND (ScheduledDate IS NULL OR ScheduledDate <= GETUTCDATE())
    ORDER BY CreatedDate ASC;
END