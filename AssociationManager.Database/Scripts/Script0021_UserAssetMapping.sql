-- Script 0021: Add User Asset Mapping Procedure
GO
CREATE OR ALTER PROCEDURE sp_Occupancy_GetByUserId
    @UserId INT,
    @TenantId INT,
    @AssociationId INT
AS
BEGIN
    SELECT o.* 
    FROM Occupancy o
    JOIN Persons p ON o.PersonId = p.PersonId
    -- Assuming Link User to Person by Email for now if no direct UserId in Persons
    JOIN Users u ON p.Email = u.Email
    WHERE u.UserId = @UserId 
      AND o.TenantId = @TenantId 
      AND o.AssociationId = @AssociationId;
END
GO
