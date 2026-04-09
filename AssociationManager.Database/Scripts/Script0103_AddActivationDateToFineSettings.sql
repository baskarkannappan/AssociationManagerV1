-- Script0103_AddActivationDateToFineSettings.sql
-- Adds ActivationDate to FineSettings to prevent retroactive fine calculations

IF NOT EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID(N'[assoc].[FineSettings]') AND name = 'ActivationDate')
BEGIN
    ALTER TABLE [assoc].[FineSettings] ADD [ActivationDate] DATETIME NULL;
END
GO

-- Update Stored Procedure
IF EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[assoc].[sp_FineSettings_Upsert]') AND type in (N'P', N'PC'))
    DROP PROCEDURE [assoc].[sp_FineSettings_Upsert];
GO

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
GO
