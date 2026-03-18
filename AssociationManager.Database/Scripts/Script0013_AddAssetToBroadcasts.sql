USE AssociationManagerV1;
GO

-- Add AssetId to Broadcasts for targeted announcements
IF NOT EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID('Broadcasts') AND name = 'AssetId')
BEGIN
    ALTER TABLE Broadcasts
    ADD AssetId INT NULL;

    ALTER TABLE Broadcasts
    ADD CONSTRAINT FK_Broadcasts_Assets FOREIGN KEY (AssetId) REFERENCES Assets(AssetId);
END
GO
