-- Script0102_RefineRevenueCalculation.sql
-- Updates the Total Revenue (30d) calculation to exclude internal settlements

IF EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[assoc].[sp_Dashboard_GetRevenue30D]') AND type in (N'P', N'PC'))
    DROP PROCEDURE [assoc].[sp_Dashboard_GetRevenue30D];
GO

CREATE PROCEDURE assoc.sp_Dashboard_GetRevenue30D
    @TenantId INT,
    @AssociationId INT
AS
BEGIN
    SET NOCOUNT ON;
    SELECT ISNULL(SUM(Amount), 0) 
    FROM assoc.Payments 
    WHERE TenantId = @TenantId 
    AND AssociationId = @AssociationId 
    AND Status IN ('Paid', 'Completed', 'Captured')
    AND CreatedDate >= DATEADD(DAY, -30, GETDATE())
    AND (
        (Notes IS NULL) OR 
        (Notes NOT LIKE '%Settled%' AND Notes NOT LIKE '%Deduction%' AND Notes NOT LIKE '%Adjustment%')
    );
END
GO
