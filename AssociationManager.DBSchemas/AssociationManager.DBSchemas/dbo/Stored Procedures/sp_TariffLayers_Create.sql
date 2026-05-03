-- 11. sp_TariffLayers_Create
CREATE   PROCEDURE sp_TariffLayers_Create
    @TariffGroupId INT,
    @TenantId INT,
    @AssociationId INT = NULL,
    @Name NVARCHAR(100),
    @BaseRate DECIMAL(18, 2),
    @Frequency NVARCHAR(50),
    @CalculationType NVARCHAR(50),
    @AccountingCategory NVARCHAR(100) = NULL
AS
BEGIN
    INSERT INTO TariffLayers (TariffGroupId, TenantId, AssociationId, Name, BaseRate, Frequency, CalculationType, AccountingCategory)
    VALUES (@TariffGroupId, @TenantId, @AssociationId, @Name, @BaseRate, @Frequency, @CalculationType, @AccountingCategory);

    SELECT SCOPE_IDENTITY();
END