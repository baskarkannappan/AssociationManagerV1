-- Script0084_FineSettings.sql
-- Create FineSettings table to house modular fine configuration for associations.
-- This table supports the 5 core scenarios (Percentage, Flat, One-time, etc.).

CREATE TABLE assoc.FineSettings (
    FineSettingsId INT IDENTITY(1,1) PRIMARY KEY,
    AssociationId INT NOT NULL,
    TenantId INT NOT NULL,
    StrategyType NVARCHAR(50) NOT NULL DEFAULT 'None', -- Percentage, FlatAmount, OneTimeFlat, etc.
    FineValue DECIMAL(18, 2) NOT NULL DEFAULT 0,
    GracePeriodDays INT NOT NULL DEFAULT 0,
    IsCompounding BIT NOT NULL DEFAULT 0, -- Used for Cumulative Percentage
    Frequency NVARCHAR(20) NOT NULL DEFAULT 'Monthly', -- Monthly, OneTime
    LastUpdated DATETIME NOT NULL DEFAULT GETUTCDATE(),
    LastUpdatedBy NVARCHAR(255),
    CONSTRAINT FK_FineSettings_Association FOREIGN KEY (AssociationId) REFERENCES corp.Associations(AssociationId)
);

CREATE INDEX IX_FineSettings_Association ON assoc.FineSettings(AssociationId);
GO

-- Stored Procedure for Upsert
CREATE OR ALTER PROCEDURE assoc.sp_FineSettings_Upsert
    @AssociationId INT,
    @TenantId INT,
    @StrategyType NVARCHAR(50),
    @FineValue DECIMAL(18, 2),
    @GracePeriodDays INT,
    @IsCompounding BIT,
    @Frequency NVARCHAR(20),
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
            LastUpdated = GETUTCDATE(),
            LastUpdatedBy = CAST(@UserId AS NVARCHAR(255))
        WHERE AssociationId = @AssociationId;
    END
    ELSE
    BEGIN
        INSERT INTO assoc.FineSettings (AssociationId, TenantId, StrategyType, FineValue, GracePeriodDays, IsCompounding, Frequency, LastUpdatedBy)
        VALUES (@AssociationId, @TenantId, @StrategyType, @FineValue, @GracePeriodDays, @IsCompounding, @Frequency, CAST(@UserId AS NVARCHAR(255)));
    END
END;
GO

-- Stored Procedure for Get
CREATE OR ALTER PROCEDURE assoc.sp_FineSettings_Get
    @AssociationId INT
AS
BEGIN
    SET NOCOUNT ON;
    SELECT * FROM assoc.FineSettings WHERE AssociationId = @AssociationId;
END;
GO
