
-- STORED PROCEDURES

CREATE   PROCEDURE [assoc].[sp_CommunicationLogs_GetById]
    @Id INT,
    @TenantId INT,
    @AssociationId INT
AS
BEGIN
    SELECT * FROM [assoc].[CommunicationLogs]
    WHERE LogId = @Id AND TenantId = @TenantId AND AssociationId = @AssociationId;
END