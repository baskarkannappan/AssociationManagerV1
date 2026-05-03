-- 12. sp_TariffGroups_Create
CREATE   PROCEDURE sp_TariffGroups_Create
    @TenantId INT,
    @AssociationId INT = NULL,
    @Name NVARCHAR(100),
    @Description NVARCHAR(MAX) = NULL
AS
BEGIN
    INSERT INTO TariffGroups (TenantId, AssociationId, Name, Description)
    VALUES (@TenantId, @AssociationId, @Name, @Description);

    SELECT SCOPE_IDENTITY();
END