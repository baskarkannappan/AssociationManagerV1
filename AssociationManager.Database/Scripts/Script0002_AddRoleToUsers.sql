IF NOT EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID('Users') AND name = 'Role')
BEGIN
    ALTER TABLE Users ADD Role NVARCHAR(50) NOT NULL DEFAULT 'User';
END
GO
