/*
    Script 0020: Plan Management
    Adds stored procedure for creating and updating subscription plans.
*/

GO
CREATE OR ALTER PROCEDURE sp_SubscriptionPlans_Upsert
    @PlanId INT = NULL,
    @Name NVARCHAR(100),
    @BasePrice DECIMAL(18, 2),
    @PricePerAsset DECIMAL(18, 2),
    @IsActive BIT
AS
BEGIN
    IF @PlanId IS NOT NULL AND EXISTS(SELECT 1 FROM SubscriptionPlans WHERE PlanId = @PlanId)
    BEGIN
        UPDATE SubscriptionPlans 
        SET Name = @Name, 
            BasePrice = @BasePrice, 
            PricePerAsset = @PricePerAsset, 
            IsActive = @IsActive
        WHERE PlanId = @PlanId;
    END
    ELSE
    BEGIN
        INSERT INTO SubscriptionPlans (Name, BasePrice, PricePerAsset, IsActive)
        VALUES (@Name, @BasePrice, @PricePerAsset, @IsActive);
    END
END
GO
