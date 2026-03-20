-- Add AssociationId to TariffGroups and TariffLayers
IF NOT EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID('TariffGroups') AND name = 'AssociationId')
BEGIN
    ALTER TABLE TariffGroups ADD AssociationId INT NULL;
END
GO

IF NOT EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID('TariffLayers') AND name = 'AssociationId')
BEGIN
    ALTER TABLE TariffLayers ADD AssociationId INT NULL;
END
GO

-- Update sp_TariffGroups_GetByTenantId to support scoping
CREATE OR ALTER PROCEDURE sp_TariffGroups_GetByTenantId
    @TenantId INT,
    @AssociationId INT = NULL
AS
BEGIN
    SELECT * FROM TariffGroups 
    WHERE TenantId = @TenantId 
      AND (AssociationId = @AssociationId OR @AssociationId IS NULL OR @AssociationId = 0)
    ORDER BY Name;
END
GO

-- Update sp_TariffGroups_Create
CREATE OR ALTER PROCEDURE sp_TariffGroups_Create
    @TenantId INT,
    @AssociationId INT = NULL,
    @Name NVARCHAR(100),
    @Description NVARCHAR(MAX) = NULL
AS
BEGIN
    INSERT INTO TariffGroups (TenantId, AssociationId, Name, Description)
    OUTPUT INSERTED.TariffGroupId
    VALUES (@TenantId, @AssociationId, @Name, @Description);
END
GO

-- Update sp_TariffLayers_Create
CREATE OR ALTER PROCEDURE sp_TariffLayers_Create
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
    OUTPUT INSERTED.TariffLayerId
    VALUES (@TariffGroupId, @TenantId, @AssociationId, @Name, @BaseRate, @Frequency, @CalculationType, @AccountingCategory);
END
GO
