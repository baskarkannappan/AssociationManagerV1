-- BROADCASTS
CREATE   PROCEDURE assoc.sp_Broadcasts_GetById @Id INT, @TenantId INT, @AssociationId INT AS 
BEGIN
    SELECT b.*, u.Name as AuthorName, a.Name as AssetName
    FROM assoc.Broadcasts b 
    LEFT JOIN assoc.Users u ON b.CreatedBy = u.UserId
    LEFT JOIN assoc.Assets a ON b.AssetId = a.AssetId
    WHERE b.BroadcastId = @Id AND b.AssociationId = @AssociationId;
END
GO