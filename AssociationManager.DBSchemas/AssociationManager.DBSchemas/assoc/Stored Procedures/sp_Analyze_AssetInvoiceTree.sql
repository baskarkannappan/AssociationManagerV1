
CREATE PROCEDURE assoc.sp_Analyze_AssetInvoiceTree
    @AssociationId INT
AS
BEGIN
    SET NOCOUNT ON;

    -- Recursive CTE to build Asset Hierarchy
    ;WITH AssetHierarchy AS (
        -- Root assets (those without a parent)
        SELECT 
            AssetId, 
            ParentId, 
            Name, 
            AssetType,
            CAST(Name AS NVARCHAR(MAX)) AS HierarchyPath,
            0 AS [Level],
            CAST(RIGHT('0000000000' + CAST(AssetId AS VARCHAR(10)), 10) AS VARCHAR(MAX)) AS SortKey
        FROM assoc.Assets
        WHERE AssociationId = @AssociationId 
          AND ParentId IS NULL 
          AND IsActive = 1

        UNION ALL

        -- Child assets (recursive part)
        SELECT 
            a.AssetId, 
            a.ParentId, 
            a.Name, 
            a.AssetType,
            ah.HierarchyPath + ' > ' + a.Name AS HierarchyPath,
            ah.[Level] + 1 AS [Level],
            ah.SortKey + ' > ' + CAST(RIGHT('0000000000' + CAST(a.AssetId AS VARCHAR(10)), 10) AS VARCHAR(MAX)) AS SortKey
        FROM assoc.Assets a
        INNER JOIN AssetHierarchy ah ON a.ParentId = ah.AssetId
        WHERE a.IsActive = 1
    )
    SELECT 
        ah.[Level],
        ah.HierarchyPath,
        ah.Name AS AssetName,
        ah.AssetType,
        p.FirstName + ' ' + p.LastName AS OwnerName,
        o.OccupancyType,
        o.IsPrimaryContact,
        i.InvoiceId,
        i.Title AS InvoiceTitle,
        i.Amount AS InvoiceAmount,
        i.Status AS InvoiceStatus,
        i.DueDate AS InvoiceDueDate
    FROM AssetHierarchy ah
    -- Join with Occupancy and Persons to get Owner details
    LEFT JOIN assoc.Occupancy o ON ah.AssetId = o.AssetId
    LEFT JOIN assoc.Persons p ON o.PersonId = p.PersonId
    -- Join with Invoices to get status
    LEFT JOIN assoc.Invoices i ON ah.AssetId = i.AssetId
    ORDER BY ah.SortKey, o.IsPrimaryContact DESC, i.DueDate DESC;
END