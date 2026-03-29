IF NOT EXISTS (SELECT * FROM sys.schemas WHERE name = 'assoc')
BEGIN
    EXEC('CREATE SCHEMA assoc')
END
GO

-- 1. Analyze Asset Tariffs
CREATE OR ALTER PROCEDURE assoc.sp_Analyze_AssetTariffs
    @AssociationId INT = NULL,
    @AssetId INT = NULL
AS
BEGIN
    SELECT 
        a.AssetId,
        a.Name AS AssetName,
        a.AssetType,
        tl.Name AS TariffName,
        tl.BaseRate,
        at.CustomAmount,
        at.IsActive,
        at.IsRecurring,
        tg.Name AS GroupName
    FROM assoc.Assets a
    JOIN assoc.AssetTariffs at ON a.AssetId = at.AssetId
    JOIN assoc.TariffLayers tl ON at.TariffLayerId = tl.TariffLayerId
    JOIN assoc.TariffGroups tg ON tl.TariffGroupId = tg.TariffGroupId
    WHERE (@AssociationId IS NULL OR a.AssociationId = @AssociationId)
      AND (@AssetId IS NULL OR a.AssetId = @AssetId)
    ORDER BY a.Name, tg.Name, tl.Name;
END
GO

-- 2. Analyze Asset Financials (Invoices & Balance)
CREATE OR ALTER PROCEDURE assoc.sp_Analyze_AssetFinancials
    @AssetId INT
AS
BEGIN
    -- Summary
    SELECT 
        a.Name AS AssetName,
        (SELECT SUM(CASE WHEN Type = 'Debit' THEN Amount ELSE -Amount END) FROM assoc.Transactions WHERE AssetId = @AssetId) AS CurrentBalance
    FROM assoc.Assets a WHERE a.AssetId = @AssetId;

    -- Recent Invoices
    SELECT TOP 20
        InvoiceId, Title, Amount, Status, CreatedDate, DueDate
    FROM assoc.Invoices 
    WHERE AssetId = @AssetId
    ORDER BY CreatedDate DESC;

    -- Recent Transactions
    SELECT TOP 20
        TransactionId, Type, Amount, Category, Description, TransactionDate
    FROM assoc.Transactions
    WHERE AssetId = @AssetId
    ORDER BY TransactionDate DESC;
END
GO

-- 3. Analyze Resident Mapping
CREATE OR ALTER PROCEDURE assoc.sp_Analyze_ResidentMapping
    @AssociationId INT = NULL
AS
BEGIN
    SELECT 
        a.Name AS AssetName,
        a.AssetType,
        p.FirstName + ' ' + p.LastName AS ResidentName,
        p.Email,
        p.Phone,
        o.OccupancyType,
        o.IsPrimaryContact,
        o.StartDate,
        o.EndDate
    FROM assoc.Assets a
    LEFT JOIN assoc.Occupancy o ON a.AssetId = o.AssetId
    LEFT JOIN assoc.Persons p ON o.PersonId = p.PersonId
    WHERE (@AssociationId IS NULL OR a.AssociationId = @AssociationId)
    ORDER BY a.Name, o.IsPrimaryContact DESC;
END
GO

-- 4. Analyze Batch History
CREATE OR ALTER PROCEDURE assoc.sp_Analyze_BatchHistory
    @AssociationId INT = NULL
AS
BEGIN
    SELECT 
        bb.BillingBatchId,
        bb.Month,
        bb.Year,
        bb.Status,
        bb.InvoicesGenerated,
        bb.TotalAmount,
        bb.CreatedDate,
        a.Name AS AssociationName
    FROM assoc.BillingBatches bb
    JOIN corp.Associations a ON bb.AssociationId = a.AssociationId
    WHERE (@AssociationId IS NULL OR bb.AssociationId = @AssociationId)
    ORDER BY bb.CreatedDate DESC;
END
GO

-- 5. Identify Orphaned Assets (No Tariffs or No Residents)
CREATE OR ALTER PROCEDURE assoc.sp_Analyze_OrphanedData
    @AssociationId INT
AS
BEGIN
    -- No Residents
    SELECT 'No Residents' AS Issue, AssetId, Name, AssetType
    FROM assoc.Assets a
    WHERE a.AssociationId = @AssociationId
      AND NOT EXISTS (SELECT 1 FROM assoc.Occupancy o WHERE o.AssetId = a.AssetId)
    
    UNION ALL

    -- No Tariffs
    SELECT 'No Tariffs' AS Issue, AssetId, Name, AssetType
    FROM assoc.Assets a
    WHERE a.AssociationId = @AssociationId
      AND NOT EXISTS (SELECT 1 FROM assoc.AssetTariffs at WHERE at.AssetId = a.AssetId)
    ORDER BY Issue, Name;
END
GO
