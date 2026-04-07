-- Script0092_PlatformWalletOperations.sql
-- 1. Add PlatformWalletBalance to Associations table in corp schema
IF NOT EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID('corp.Associations') AND name = 'PlatformWalletBalance')
BEGIN
    ALTER TABLE corp.Associations ADD PlatformWalletBalance DECIMAL(18,2) NOT NULL DEFAULT 0;
END
GO

-- 2. Create PlatformAdvancePayments table in corp schema
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'PlatformAdvancePayments' AND schema_id = SCHEMA_ID('corp'))
BEGIN
    CREATE TABLE corp.PlatformAdvancePayments (
        PlatformAdvanceId INT PRIMARY KEY IDENTITY(1,1),
        AssociationId INT NOT NULL,
        Amount DECIMAL(18,2) NOT NULL,
        Date DATETIME NOT NULL DEFAULT GETUTCDATE(),
        Status NVARCHAR(50) NOT NULL DEFAULT 'Completed', -- Completed, Reversed
        TransactionRef NVARCHAR(255) NULL,
        Description NVARCHAR(500) NULL,
        Notes NVARCHAR(MAX) NULL,
        CreatedDate DATETIME NOT NULL DEFAULT GETUTCDATE(),
        
        CONSTRAINT FK_PlatformAdvancePayments_Association FOREIGN KEY (AssociationId) REFERENCES corp.Associations(AssociationId)
    );
END
GO

-- 3. Stored Procedures for Wallet Management

CREATE OR ALTER PROCEDURE corp.sp_Associations_GetWalletBalance
    @AssociationId INT
AS
BEGIN
    SELECT ISNULL(PlatformWalletBalance, 0) FROM corp.Associations WHERE AssociationId = @AssociationId;
END;
GO

CREATE OR ALTER PROCEDURE corp.sp_Associations_UpdateWalletBalance
    @AssociationId INT,
    @Delta DECIMAL(18,2)
AS
BEGIN
    UPDATE corp.Associations
    SET PlatformWalletBalance = ISNULL(PlatformWalletBalance, 0) + @Delta
    WHERE AssociationId = @AssociationId;
END;
GO

CREATE OR ALTER PROCEDURE corp.sp_PlatformAdvancePayments_Insert
    @AssociationId INT,
    @Amount DECIMAL(18,2),
    @Status NVARCHAR(50),
    @TransactionRef NVARCHAR(255) = NULL,
    @Description NVARCHAR(500) = NULL,
    @Notes NVARCHAR(MAX) = NULL
AS
BEGIN
    INSERT INTO corp.PlatformAdvancePayments (AssociationId, Amount, Status, TransactionRef, Description, Notes)
    VALUES (@AssociationId, @Amount, @Status, @TransactionRef, @Description, @Notes);
    SELECT SCOPE_IDENTITY();
END;
GO

CREATE OR ALTER PROCEDURE corp.sp_PlatformAdvancePayments_GetPaged
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
GO
