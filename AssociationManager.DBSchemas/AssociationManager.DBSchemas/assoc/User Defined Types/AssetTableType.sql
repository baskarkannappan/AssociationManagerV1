CREATE TYPE [assoc].[AssetTableType] AS TABLE (
    [ParentId]      INT            NULL,
    [TenantId]      INT            NOT NULL,
    [AssociationId] INT            NOT NULL,
    [Name]          NVARCHAR (250) NOT NULL,
    [Description]   NVARCHAR (MAX) NULL,
    [AssetType]     INT            NOT NULL,
    [MetadataJson]  NVARCHAR (MAX) NULL,
    [CreatedDate]   DATETIME       NOT NULL,
    [CreatedBy]     INT            NOT NULL,
    [IsActive]      BIT            NOT NULL);

