-- Script0067_FixAdvanceProcedures.sql
-- Fixes for wallet balances and advance payment visibility.

-- 1. Fix Status filter in Advances History
CREATE   PROCEDURE assoc.sp_Payments_GetAdvances
    @AssociationId INT,
    @TenantId INT,
    @UserId INT = NULL,
    @AssetId INT = NULL
AS
BEGIN
    SET NOCOUNT ON;

    SELECT 
        p.PaymentId,
        p.Amount,
        p.Currency,
        p.CreatedDate,
        p.Status,
        p.GatewayReference,
        p.Notes,
        a.Name as UnitName,
        u.Name as ResidentName,
        u.Email as ResidentEmail
    FROM assoc.Payments p
    LEFT JOIN assoc.Assets a ON p.AssetId = a.AssetId
    LEFT JOIN assoc.Users u ON p.UserId = u.UserId
    WHERE p.TenantId = @TenantId
      AND p.AssociationId = @AssociationId
      AND p.InvoiceId IS NULL  -- Only advances
      AND p.Status IN ('Paid', 'Completed') -- FIX: Include Completed
      AND (@UserId IS NULL OR p.UserId = @UserId)
      AND (@AssetId IS NULL OR p.AssetId = @AssetId)
    ORDER BY p.CreatedDate DESC;
END;