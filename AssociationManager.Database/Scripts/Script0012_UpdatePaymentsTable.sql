USE AssociationManagerV1;
GO

-- Add AssetId and Notes to Payments
IF NOT EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID('Payments') AND name = 'AssetId')
BEGIN
    ALTER TABLE Payments ADD AssetId INT;
    ALTER TABLE Payments ADD CONSTRAINT FK_Payments_Assets FOREIGN KEY (AssetId) REFERENCES Assets(AssetId);
END
GO

IF NOT EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID('Payments') AND name = 'Notes')
BEGIN
    ALTER TABLE Payments ADD Notes NVARCHAR(500);
END
GO
