-- CREATE TABLES IN ASSOC SCHEMA
IF NOT EXISTS (SELECT * FROM sys.tables WHERE SCHEMA_NAME(schema_id) = 'assoc' AND name = 'Users')
BEGIN
    CREATE TABLE assoc.Users (
        UserId INT PRIMARY KEY IDENTITY(1,1),
        TenantId INT NULL, -- Optional mapping to a tenant if needed
        GoogleId NVARCHAR(255) NULL,
        Email NVARCHAR(255) NOT NULL,
        Name NVARCHAR(255) NOT NULL,
        PictureUrl NVARCHAR(MAX) NULL,
        Role NVARCHAR(50) NOT NULL DEFAULT 'User',
        CreatedDate DATETIME NOT NULL DEFAULT GETUTCDATE(),
        LastLoginDate DATETIME NULL,
        IsActive BIT NOT NULL DEFAULT 1
    );
    CREATE INDEX IX_AssocUsers_Email ON assoc.Users(Email);
    CREATE INDEX IX_AssocUsers_GoogleId ON assoc.Users(GoogleId);
END
GO

IF NOT EXISTS (SELECT * FROM sys.tables WHERE SCHEMA_NAME(schema_id) = 'assoc' AND name = 'UserAssociations')
BEGIN
    CREATE TABLE assoc.UserAssociations (
        UserId INT NOT NULL,
        AssociationId INT NOT NULL,
        Role NVARCHAR(50) NOT NULL,
        CreatedDate DATETIME2 NOT NULL DEFAULT GETUTCDATE(),
        PRIMARY KEY (UserId, AssociationId),
        FOREIGN KEY (UserId) REFERENCES assoc.Users(UserId),
        FOREIGN KEY (AssociationId) REFERENCES corp.Associations(AssociationId)
    );
    CREATE INDEX IX_AssocUserAssociations_UserId ON assoc.UserAssociations(UserId);
    CREATE INDEX IX_AssocUserAssociations_AssociationId ON assoc.UserAssociations(AssociationId);
END
GO

-- REFRESH TOKENS FOR ASSOC (If we want complete isolation of sessions)
IF NOT EXISTS (SELECT * FROM sys.tables WHERE SCHEMA_NAME(schema_id) = 'assoc' AND name = 'RefreshTokens')
BEGIN
    CREATE TABLE assoc.RefreshTokens (
        RefreshTokenId INT PRIMARY KEY IDENTITY(1,1),
        UserId INT NOT NULL,
        Token NVARCHAR(MAX) NOT NULL,
        ExpiryDate DATETIME NOT NULL,
        CreatedDate DATETIME NOT NULL DEFAULT GETUTCDATE(),
        IsRevoked BIT NOT NULL DEFAULT 0,
        FOREIGN KEY (UserId) REFERENCES assoc.Users(UserId)
    );
END
GO

-- STORED PROCEDURES FOR ASSOC USERS
CREATE OR ALTER PROCEDURE assoc.sp_Users_GetById @Id INT AS 
BEGIN SELECT * FROM assoc.Users WHERE UserId = @Id; END
GO
CREATE OR ALTER PROCEDURE assoc.sp_Users_GetByGoogleId @GoogleId NVARCHAR(255) AS 
BEGIN SELECT * FROM assoc.Users WHERE GoogleId = @GoogleId; END
GO
CREATE OR ALTER PROCEDURE assoc.sp_Users_GetByEmail @Email NVARCHAR(255) AS 
BEGIN SELECT * FROM assoc.Users WHERE Email = @Email; END
GO
CREATE OR ALTER PROCEDURE assoc.sp_Users_GetByAssociationId @AssociationId INT AS 
BEGIN 
    SELECT u.*, ua.Role 
    FROM assoc.Users u 
    JOIN assoc.UserAssociations ua ON u.UserId = ua.UserId 
    WHERE ua.AssociationId = @AssociationId; 
END
GO
CREATE OR ALTER PROCEDURE assoc.sp_Users_Create @TenantId INT = NULL, @GoogleId NVARCHAR(255) = NULL, @Email NVARCHAR(255), @Name NVARCHAR(255), @PictureUrl NVARCHAR(MAX) = NULL, @Role NVARCHAR(50) = 'User', @CreatedDate DATETIME, @LastLoginDate DATETIME = NULL, @IsActive BIT = 1 AS 
BEGIN 
    INSERT INTO assoc.Users (TenantId, GoogleId, Email, Name, PictureUrl, Role, CreatedDate, LastLoginDate, IsActive) 
    OUTPUT INSERTED.UserId 
    VALUES (@TenantId, @GoogleId, @Email, @Name, @PictureUrl, @Role, @CreatedDate, @LastLoginDate, @IsActive); 
END
GO
CREATE OR ALTER PROCEDURE assoc.sp_Users_Update @UserId INT, @Name NVARCHAR(255), @PictureUrl NVARCHAR(MAX), @Role NVARCHAR(50), @LastLoginDate DATETIME, @IsActive BIT AS 
BEGIN 
    UPDATE assoc.Users SET Name = @Name, PictureUrl = @PictureUrl, Role = @Role, LastLoginDate = @LastLoginDate, IsActive = @IsActive 
    WHERE UserId = @UserId; 
END
GO
CREATE OR ALTER PROCEDURE assoc.sp_Users_GetAll AS 
BEGIN SELECT * FROM assoc.Users; END
GO

-- STORED PROCEDURES FOR ASSOC USER ASSOCIATIONS
CREATE OR ALTER PROCEDURE assoc.sp_UserAssociations_CheckExists @UserId INT, @AssociationId INT AS 
BEGIN SELECT COUNT(1) FROM assoc.UserAssociations WHERE UserId = @UserId AND AssociationId = @AssociationId; END
GO
CREATE OR ALTER PROCEDURE assoc.sp_UserAssociations_Upsert @UserId INT, @AssociationId INT, @Role NVARCHAR(50) AS 
BEGIN 
    IF EXISTS (SELECT 1 FROM assoc.UserAssociations WHERE UserId = @UserId AND AssociationId = @AssociationId)
        UPDATE assoc.UserAssociations SET Role = @Role WHERE UserId = @UserId AND AssociationId = @AssociationId
    ELSE
        INSERT INTO assoc.UserAssociations (UserId, AssociationId, Role) VALUES (@UserId, @AssociationId, @Role);
END
GO
CREATE OR ALTER PROCEDURE assoc.sp_UserAssociations_GetRole @UserId INT, @AssociationId INT AS 
BEGIN SELECT Role FROM assoc.UserAssociations WHERE UserId = @UserId AND AssociationId = @AssociationId; END
GO
CREATE OR ALTER PROCEDURE assoc.sp_UserAssociations_Delete @UserId INT, @AssociationId INT AS 
BEGIN DELETE FROM assoc.UserAssociations WHERE UserId = @UserId AND AssociationId = @AssociationId; END
GO
CREATE OR ALTER PROCEDURE assoc.sp_UserAssociations_IsAuthorised @UserId INT, @AssociationId INT AS 
BEGIN 
    IF EXISTS (SELECT 1 FROM assoc.Users WHERE UserId = @UserId AND Role IN ('SystemAdmin', 'PlatformAdmin'))
    BEGIN
        SELECT 1;
    END
    ELSE
    BEGIN
        SELECT COUNT(1) FROM assoc.UserAssociations 
        WHERE UserId = @UserId AND AssociationId = @AssociationId; 
    END
END
GO

-- GET ASSOCIATIONS BY USER ID (ASSOC SCHEMA)
CREATE OR ALTER PROCEDURE assoc.sp_Associations_GetByUserId @UserId INT AS 
BEGIN
    IF EXISTS (SELECT 1 FROM assoc.Users WHERE UserId = @UserId AND Role IN ('SystemAdmin', 'PlatformAdmin'))
    BEGIN
        SELECT * FROM corp.Associations;
    END
    ELSE
    BEGIN
        -- 1. Direct mappings in assoc.UserAssociations
        SELECT DISTINCT a.* FROM corp.Associations a
        INNER JOIN assoc.UserAssociations ua ON a.AssociationId = ua.AssociationId
        WHERE ua.UserId = @UserId
        
        UNION

        -- 2. Indirect mappings via Occupancy (using email bridge)
        SELECT DISTINCT a.* FROM corp.Associations a
        INNER JOIN assoc.Occupancy o ON a.AssociationId = o.AssociationId
        INNER JOIN assoc.Persons p ON o.PersonId = p.PersonId
        INNER JOIN assoc.Users u ON p.Email = u.Email
        WHERE u.UserId = @UserId
    END
END
GO
GO

-- REFRESH TOKENS PROCEDURES FOR ASSOC
CREATE OR ALTER PROCEDURE assoc.sp_RefreshTokens_GetByToken @Token NVARCHAR(MAX) AS 
BEGIN SELECT * FROM assoc.RefreshTokens WHERE Token = @Token; END
GO
CREATE OR ALTER PROCEDURE assoc.sp_RefreshTokens_Upsert @UserId INT, @Token NVARCHAR(MAX), @ExpiryDate DATETIME, @CreatedDate DATETIME AS 
BEGIN
    IF EXISTS (SELECT 1 FROM assoc.RefreshTokens WHERE UserId = @UserId)
        UPDATE assoc.RefreshTokens SET Token = @Token, ExpiryDate = @ExpiryDate WHERE UserId = @UserId
    ELSE
        INSERT INTO assoc.RefreshTokens (UserId, Token, ExpiryDate, CreatedDate) VALUES (@UserId, @Token, @ExpiryDate, @CreatedDate);
END
GO
CREATE OR ALTER PROCEDURE assoc.sp_RefreshTokens_Delete @UserId INT AS 
BEGIN DELETE FROM assoc.RefreshTokens WHERE UserId = @UserId; END
GO
