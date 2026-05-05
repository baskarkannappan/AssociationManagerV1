CREATE OR ALTER PROCEDURE assoc.sp_Finance_GetUsersBalancesBulk
    @AssociationId INT,
    @UserIds NVARCHAR(MAX) -- Comma-separated list of UserIds
AS
BEGIN
    SET NOCOUNT ON;

    -- 1. Parse UserIds into a table variable
    DECLARE @UserList TABLE (UserId INT PRIMARY KEY);
    INSERT INTO @UserList (UserId)
    SELECT CAST(value AS INT) FROM STRING_SPLIT(@UserIds, ',');

    -- 2. Resolve all Assets for these Users
    -- We need this to calculate credits (which are often tied to assets)
    DECLARE @UserAssets TABLE (UserId INT, AssetId INT, PRIMARY KEY (UserId, AssetId));
    INSERT INTO @UserAssets (UserId, AssetId)
    SELECT DISTINCT u.UserId, o.AssetId
    FROM assoc.Users u
    INNER JOIN @UserList ul ON u.UserId = ul.UserId
    INNER JOIN assoc.Persons p ON u.Email = p.Email
    INNER JOIN assoc.Occupancy o ON p.PersonId = o.PersonId
    WHERE o.AssociationId = @AssociationId;

    -- 3. Get Fine Settings
    DECLARE @StrategyType NVARCHAR(50), @FineValue DECIMAL(18,2), @GracePeriodDays INT, @IsCompounding BIT, @ActivationDate DATETIME;
    SELECT TOP 1 @StrategyType = StrategyType, @FineValue = FineValue, @GracePeriodDays = GracePeriodDays, @IsCompounding = IsCompounding, @ActivationDate = ActivationDate 
    FROM assoc.FineSettings 
    WHERE AssociationId = @AssociationId;

    -- 4. Get Data from Snapshot Table
    SELECT 
        ul.UserId,
        ISNULL(SUM(CASE WHEN s.OutstandingAmount > s.PaidAmount THEN s.OutstandingAmount - s.PaidAmount ELSE 0 END), 0) as TotalUnpaid,
        ISNULL(SUM(s.AdvanceBalance), 0) as TotalAdvanceCredits
    FROM @UserList ul
    INNER JOIN assoc.Users u ON ul.UserId = u.UserId
    INNER JOIN assoc.Persons p ON u.Email = p.Email
    INNER JOIN assoc.Occupancy o ON p.PersonId = o.PersonId
    INNER JOIN assoc.AssetBalancesSnapshot s ON o.AssetId = s.AssetId
    WHERE o.AssociationId = @AssociationId
    GROUP BY ul.UserId;
END
GO
