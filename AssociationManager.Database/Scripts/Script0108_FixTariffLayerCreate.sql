-- Update sp_TariffLayers_Create to support AssociationId
CREATE OR ALTER PROCEDURE assoc.sp_TariffLayers_Create 
    @TariffGroupId INT, 
    @TenantId INT, 
    @AssociationId INT = NULL, 
    @Name NVARCHAR(100), 
    @BaseRate DECIMAL(18, 2), 
    @Frequency INT, 
    @CalculationType INT, 
    @AccountingCategory NVARCHAR(100) = NULL 
AS 
BEGIN 
    INSERT INTO assoc.TariffLayers (
        TariffGroupId, 
        TenantId, 
        AssociationId, 
        Name, 
        BaseRate, 
        Frequency, 
        CalculationType, 
        AccountingCategory
    ) 
    VALUES (
        @TariffGroupId, 
        @TenantId, 
        @AssociationId, 
        @Name, 
        @BaseRate, 
        @Frequency, 
        @CalculationType, 
        @AccountingCategory
    ); 
    SELECT CAST(SCOPE_IDENTITY() as int); 
END
GO
