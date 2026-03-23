CREATE   PROCEDURE corp.sp_SubscriptionPlans_Upsert @PlanId INT, @Name NVARCHAR(100), @BasePrice DECIMAL(18,2), @PricePerAsset DECIMAL(18,2), @IsActive BIT AS 
BEGIN
    IF EXISTS (SELECT 1 FROM corp.SubscriptionPlans WHERE PlanId = @PlanId)
        UPDATE corp.SubscriptionPlans SET Name = @Name, BasePrice = @BasePrice, PricePerAsset = @PricePerAsset, IsActive = @IsActive WHERE PlanId = @PlanId
    ELSE
        INSERT INTO corp.SubscriptionPlans (Name, BasePrice, PricePerAsset, IsActive) VALUES (@Name, @BasePrice, @PricePerAsset, @IsActive);
END