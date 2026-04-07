CREATE   PROCEDURE corp.sp_PlatformAdvancePayments_GetPaged
    @AssociationId INT,
    @SearchTerm NVARCHAR(100) = NULL,
    @Status NVARCHAR(50) = NULL,
    @StartDate DATETIME = NULL,
    @EndDate DATETIME = NULL,
    @PageNumber INT = 1,
    @PageSize INT = 10,
    @SortColumn NVARCHAR(50) = 'Date',
    @SortDirection NVARCHAR(10) = 'DESC'
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @Offset INT = (@PageNumber - 1) * @PageSize;

    WITH FilteredResults AS (
        SELECT *, COUNT(*) OVER() as TotalCount
        FROM corp.PlatformAdvancePayments
        WHERE AssociationId = @AssociationId
          AND (@Status IS NULL OR Status = @Status)
          AND (@SearchTerm IS NULL OR Description LIKE '%' + @SearchTerm + '%' OR TransactionRef LIKE '%' + @SearchTerm + '%')
          AND (@StartDate IS NULL OR Date >= @StartDate)
          AND (@EndDate IS NULL OR Date <= @EndDate)
    )
    SELECT *
    FROM FilteredResults
    ORDER BY 
        CASE WHEN @SortDirection = 'ASC' THEN
            CASE 
                WHEN @SortColumn = 'Date' THEN CAST(Date AS NVARCHAR(50))
                WHEN @SortColumn = 'Amount' THEN RIGHT('0000000000' + CAST(ABS(Amount) * 100 AS VARCHAR(20)), 20)
                ELSE CAST(Date AS NVARCHAR(50))
            END
        END ASC,
        CASE WHEN @SortDirection = 'DESC' THEN
            CASE 
                WHEN @SortColumn = 'Date' THEN CAST(Date AS NVARCHAR(50))
                WHEN @SortColumn = 'Amount' THEN RIGHT('0000000000' + CAST(ABS(Amount) * 100 AS VARCHAR(20)), 20)
                ELSE CAST(Date AS NVARCHAR(50))
            END
        END DESC
    OFFSET @Offset ROWS
    FETCH NEXT @PageSize ROWS ONLY;
END;