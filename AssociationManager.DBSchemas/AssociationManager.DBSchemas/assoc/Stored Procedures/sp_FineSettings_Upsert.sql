CREATE PROCEDURE assoc.sp_FineSettings_Upsert
    @AssociationId INT,
    @TenantId INT,
    @StrategyType NVARCHAR(50),
    @FineValue DECIMAL(18, 2),
    @GracePeriodDays INT,
    @IsCompounding BIT,
    @Frequency NVARCHAR(20),
    @ActivationDate DATETIME = NULL,
    @UserId INT
AS
BEGIN
    SET NOCOUNT ON;
    
    IF EXISTS (SELECT 1 FROM assoc.FineSettings WHERE AssociationId = @AssociationId)
    BEGIN
        UPDATE assoc.FineSettings
        SET StrategyType = @StrategyType,
            FineValue = @FineValue,
            GracePeriodDays = @GracePeriodDays,
            IsCompounding = @IsCompounding,
            Frequency = @Frequency,
            ActivationDate = @ActivationDate,
            LastUpdated = GETUTCDATE(),
            LastUpdatedBy = CAST(@UserId AS NVARCHAR(255))
        WHERE AssociationId = @AssociationId;
    END
    ELSE
    BEGIN
        INSERT INTO assoc.FineSettings (AssociationId, TenantId, StrategyType, FineValue, GracePeriodDays, IsCompounding, Frequency, ActivationDate, LastUpdatedBy)
        VALUES (@AssociationId, @TenantId, @StrategyType, @FineValue, @GracePeriodDays, @IsCompounding, @Frequency, @ActivationDate, CAST(@UserId AS NVARCHAR(255)));
    END
END;