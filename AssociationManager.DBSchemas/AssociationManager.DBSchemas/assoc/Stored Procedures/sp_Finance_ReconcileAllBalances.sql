CREATE PROCEDURE assoc.sp_Finance_ReconcileAllBalances
    @TenantId INT,
    @AssociationId INT
AS
BEGIN
    SET NOCOUNT ON;

    -- We use a cursor or a simple loop to call the single-asset update for all assets in the association.
    -- This ensures the logic is consistent and avoids complex bulk dynamic fine calculations in one go.
    
    DECLARE @AssetId INT;
    DECLARE AssetCursor CURSOR FOR 
    SELECT AssetId FROM assoc.Assets WHERE AssociationId = @AssociationId AND TenantId = @TenantId AND IsActive = 1;

    OPEN AssetCursor;
    FETCH NEXT FROM AssetCursor INTO @AssetId;

    WHILE @@FETCH_STATUS = 0
    BEGIN
        EXEC assoc.sp_Finance_UpdateAssetBalanceSnapshot @AssetId = @AssetId, @TenantId = @TenantId, @AssociationId = @AssociationId;
        FETCH NEXT FROM AssetCursor INTO @AssetId;
    END

    CLOSE AssetCursor;
    DEALLOCATE AssetCursor;
END
GO
