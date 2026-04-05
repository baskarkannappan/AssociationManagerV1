-- Script0083_sp_PlatformPayments_GetRevenue.sql
-- Refactor: Replacing hardcoded revenue query with a standardized stored procedure.
-- Purpose: Achieving 100% architectural consistency for data access.

CREATE OR ALTER PROCEDURE corp.sp_PlatformPayments_GetRevenue
    @StartDate DATETIME,
    @EndDate DATETIME
AS
BEGIN
    SET NOCOUNT ON;
    
    SELECT ISNULL(SUM(Amount), 0) 
    FROM corp.PlatformPayments 
    WHERE PaymentDate >= @StartDate AND PaymentDate <= @EndDate;
END;
GO
