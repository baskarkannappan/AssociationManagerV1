-- Add AssociationId to TariffGroups and TariffLayers
DECLARE @TableName NVARCHAR(128) = 'TariffGroups';
DECLARE @SchemaName NVARCHAR(128) = CASE 
    WHEN OBJECT_ID('dbo.TariffGroups') IS NOT NULL THEN 'dbo'
    WHEN OBJECT_ID('assoc.TariffGroups') IS NOT NULL THEN 'assoc'
    ELSE NULL END;

IF @SchemaName IS NOT NULL
BEGIN
    IF NOT EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID(@SchemaName + '.TariffGroups') AND name = 'AssociationId')
    BEGIN
        EXEC('ALTER TABLE ' + @SchemaName + '.TariffGroups ADD AssociationId INT NULL');
    END
END
GO

DECLARE @TableName NVARCHAR(128) = 'TariffLayers';
DECLARE @SchemaName NVARCHAR(128) = CASE 
    WHEN OBJECT_ID('dbo.TariffLayers') IS NOT NULL THEN 'dbo'
    WHEN OBJECT_ID('assoc.TariffLayers') IS NOT NULL THEN 'assoc'
    ELSE NULL END;

IF @SchemaName IS NOT NULL
BEGIN
    IF NOT EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID(@SchemaName + '.TariffLayers') AND name = 'AssociationId')
    BEGIN
        EXEC('ALTER TABLE ' + @SchemaName + '.TariffLayers ADD AssociationId INT NULL');
    END
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
