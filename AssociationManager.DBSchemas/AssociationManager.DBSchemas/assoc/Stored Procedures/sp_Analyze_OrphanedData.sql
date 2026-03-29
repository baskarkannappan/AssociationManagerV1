-- 5. Identify Orphaned Assets (No Tariffs or No Residents)
CREATE   PROCEDURE assoc.sp_Analyze_OrphanedData
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