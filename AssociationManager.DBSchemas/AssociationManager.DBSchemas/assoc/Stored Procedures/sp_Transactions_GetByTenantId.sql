CREATE   PROCEDURE assoc.sp_Transactions_GetByTenantId @TenantId INT, @AssociationId INT, @StartDate DATETIME, @EndDate DATETIME AS 
BEGIN 
    SELECT * FROM assoc.Transactions 
    WHERE AssociationId = @AssociationId AND TransactionDate BETWEEN @StartDate AND @EndDate 
    ORDER BY TransactionDate DESC; 
END