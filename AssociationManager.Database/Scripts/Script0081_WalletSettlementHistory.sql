-- Script0081_WalletSettlementHistory.sql
-- Fix: Including settlements (debits) in the wallet history via UNION ALL.
-- Corrected Resident-Scoping: Linking Assets to Users via Occupancy -> Persons -> Users.

CREATE OR ALTER PROCEDURE assoc.sp_Payments_GetAdvancesPaged
    @TenantId INT,
    @AssociationId INT = NULL,
    @UserId INT = NULL,
    @AssetId INT = NULL,
    @SearchTerm NVARCHAR(255) = NULL,
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
    
    -- Calculate Offset
    DECLARE @Offset INT = (@PageNumber - 1) * @PageSize;
    
    -- Sorting Safety
    IF @SortColumn NOT IN ('ResidentName', 'UnitName', 'Amount', 'Date', 'Status', 'ReferenceId')
        SET @SortColumn = 'Date';
    
    IF @SortDirection NOT IN ('ASC', 'DESC')
        SET @SortDirection = 'DESC';

    -- CTE for Filtering and Paging
    ;WITH RawAdvances AS (
        -- 1. TOP-UPS (Credits)
        SELECT 
            p.Amount,
            p.CreatedDate AS [Date],
            p.Status,
            p.GatewayReference AS ReferenceId,
            u.Name AS ResidentName,
            a.Name AS UnitName,
            p.UserId,
            p.AssetId
        FROM assoc.Payments p
        LEFT JOIN assoc.Users u ON p.UserId = u.UserId
        LEFT JOIN assoc.Assets a ON p.AssetId = a.AssetId
        WHERE p.TenantId = @TenantId
          AND p.InvoiceId IS NULL -- Top-ups / Advances
          AND (@AssociationId IS NULL OR p.AssociationId = @AssociationId)

        UNION ALL

        -- 2. SETTLEMENTS (Debits)
        -- We include settlements from the ledger that belong to assets occupied by the user
        SELECT 
            -t.Amount AS Amount,
            t.TransactionDate AS [Date],
            'Settled' AS Status,
            t.Description AS ReferenceId,
            NULL AS ResidentName,
            a.Name AS UnitName,
            -- Map the transaction to the user requesting the history if they are an occupant
            @UserId AS UserId, 
            t.AssetId
        FROM assoc.Transactions t
        INNER JOIN assoc.Assets a ON t.AssetId = a.AssetId
        WHERE t.TenantId = @TenantId
          AND t.Category IN ('Credit Settlement', 'Internal Credit Transfer')
          AND (@AssociationId IS NULL OR t.AssociationId = @AssociationId)
          -- SECURITY: If @UserId is provided, ensure they occupy the unit the transaction belongs to
          AND (@UserId IS NULL OR EXISTS (
              SELECT 1 FROM assoc.Occupancy o 
              INNER JOIN assoc.Persons per ON o.PersonId = per.PersonId
              INNER JOIN assoc.Users usr ON per.Email = usr.Email
              WHERE o.AssetId = t.AssetId AND usr.UserId = @UserId
          ))
    ),
    FilteredAdvances AS (
        SELECT 
            Amount,
            [Date],
            Status,
            ReferenceId,
            ISNULL(ResidentName, 'System') AS ResidentName,
            ISNULL(UnitName, 'General') AS UnitName,
            COUNT(*) OVER() as TotalCount
        FROM RawAdvances
        WHERE (@UserId IS NULL OR UserId = @UserId)
          AND (@AssetId IS NULL OR AssetId = @AssetId)
          AND (
               @Status IS NULL 
               OR Status = @Status 
               OR (@Status = 'Paid' AND Status = 'Settled') 
               OR (@Status = 'Settled' AND Status = 'Settled')
          )
          AND (@StartDate IS NULL OR [Date] >= @StartDate)
          AND (@EndDate IS NULL OR [Date] <= @EndDate)
          AND (@SearchTerm IS NULL 
               OR ResidentName LIKE '%' + @SearchTerm + '%' 
               OR UnitName LIKE '%' + @SearchTerm + '%'
               OR ReferenceId LIKE '%' + @SearchTerm + '%'
          )
    )
    SELECT 
        * 
    FROM FilteredAdvances
    ORDER BY 
        CASE WHEN @SortDirection = 'ASC' THEN
            CASE 
                WHEN @SortColumn = 'ResidentName' THEN ResidentName
                WHEN @SortColumn = 'UnitName' THEN UnitName
                WHEN @SortColumn = 'Status' THEN Status
                WHEN @SortColumn = 'ReferenceId' THEN ReferenceId
            END
        END ASC,
        CASE WHEN @SortDirection = 'DESC' THEN
            CASE 
                WHEN @SortColumn = 'ResidentName' THEN ResidentName
                WHEN @SortColumn = 'UnitName' THEN UnitName
                WHEN @SortColumn = 'Status' THEN Status
                WHEN @SortColumn = 'ReferenceId' THEN ReferenceId
            END
        END DESC,
        CASE WHEN @SortDirection = 'ASC' THEN
            CASE 
                WHEN @SortColumn = 'Amount' THEN Amount
                WHEN @SortColumn = 'Date' THEN CAST([Date] AS SQL_VARIANT)
            END
        END ASC,
        CASE WHEN @SortDirection = 'DESC' THEN
            CASE 
                WHEN @SortColumn = 'Amount' THEN Amount
                WHEN @SortColumn = 'Date' THEN CAST([Date] AS SQL_VARIANT)
            END
        END DESC
    OFFSET @Offset ROWS
    FETCH NEXT @PageSize ROWS ONLY;
END;
GO
