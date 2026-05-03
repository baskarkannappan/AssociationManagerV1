
CREATE   PROCEDURE [assoc].[sp_CommunicationLogs_GetByAssociation]
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