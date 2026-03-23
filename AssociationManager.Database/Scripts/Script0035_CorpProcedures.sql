-- TENANTS
CREATE OR ALTER PROCEDURE corp.sp_Tenants_GetById @Id INT AS 
BEGIN SELECT * FROM corp.Tenants WHERE TenantId = @Id; END
GO
CREATE OR ALTER PROCEDURE corp.sp_Tenants_GetAll AS 
BEGIN SELECT * FROM corp.Tenants; END
GO
CREATE OR ALTER PROCEDURE corp.sp_Tenants_Create @Name NVARCHAR(255), @CreatedDate DATETIME, @IsActive BIT AS 
BEGIN INSERT INTO corp.Tenants (Name, CreatedDate, IsActive) OUTPUT INSERTED.TenantId VALUES (@Name, @CreatedDate, @IsActive); END
GO
CREATE OR ALTER PROCEDURE corp.sp_Tenants_Update @TenantId INT, @Name NVARCHAR(255), @IsActive BIT AS 
BEGIN UPDATE corp.Tenants SET Name = @Name, IsActive = @IsActive WHERE TenantId = @TenantId; END
GO

-- ASSOCIATIONS
CREATE OR ALTER PROCEDURE corp.sp_Associations_GetById @Id INT, @TenantId INT AS 
BEGIN SELECT * FROM corp.Associations WHERE AssociationId = @Id AND TenantId = @TenantId; END
GO
CREATE OR ALTER PROCEDURE corp.sp_Associations_GetAllByTenantId @TenantId INT AS 
BEGIN SELECT * FROM corp.Associations WHERE TenantId = @TenantId; END
GO
CREATE OR ALTER PROCEDURE corp.sp_Associations_Create @TenantId INT, @Name NVARCHAR(255), @Description NVARCHAR(MAX), @CreatedDate DATETIME, @CreatedBy INT AS 
BEGIN INSERT INTO corp.Associations (TenantId, Name, Description, CreatedDate, CreatedBy) OUTPUT INSERTED.AssociationId VALUES (@TenantId, @Name, @Description, @CreatedDate, @CreatedBy); END
GO
CREATE OR ALTER PROCEDURE corp.sp_Associations_Update @AssociationId INT, @TenantId INT, @Name NVARCHAR(255), @Description NVARCHAR(MAX) AS 
BEGIN UPDATE corp.Associations SET Name = @Name, Description = @Description WHERE AssociationId = @AssociationId AND TenantId = @TenantId; END
GO
CREATE OR ALTER PROCEDURE corp.sp_Associations_Delete @Id INT, @TenantId INT AS 
BEGIN DELETE FROM corp.Associations WHERE AssociationId = @Id AND TenantId = @TenantId; END
GO
CREATE OR ALTER PROCEDURE corp.sp_Associations_GetByUserId @UserId INT AS 
BEGIN
    SELECT DISTINCT a.* FROM corp.Associations a
    INNER JOIN corp.UserAssociations ua ON a.TenantId = ua.TenantId
    WHERE ua.UserId = @UserId AND ua.Role IN ('SystemAdmin', 'AssociationAdmin')
    UNION
    SELECT DISTINCT a.* FROM corp.Associations a
    INNER JOIN assoc.Occupancy o ON a.AssociationId = o.AssociationId
    INNER JOIN assoc.Persons p ON o.PersonId = p.PersonId
    INNER JOIN corp.Users u ON p.Email = u.Email
    WHERE u.UserId = @UserId
END
GO

-- USERS & ROLES
CREATE OR ALTER PROCEDURE corp.sp_Users_GetById @Id INT AS 
BEGIN SELECT * FROM corp.Users WHERE UserId = @Id; END
GO
CREATE OR ALTER PROCEDURE corp.sp_Users_GetByGoogleId @GoogleId NVARCHAR(255) AS 
BEGIN SELECT * FROM corp.Users WHERE GoogleId = @GoogleId; END
GO
CREATE OR ALTER PROCEDURE corp.sp_Users_GetByEmail @Email NVARCHAR(255) AS 
BEGIN SELECT * FROM corp.Users WHERE Email = @Email; END
GO
CREATE OR ALTER PROCEDURE corp.sp_Users_GetByTenantId @TenantId INT AS 
BEGIN SELECT u.*, ua.Role FROM corp.Users u JOIN corp.UserAssociations ua ON u.UserId = ua.UserId WHERE ua.TenantId = @TenantId; END
GO
CREATE OR ALTER PROCEDURE corp.sp_Users_Create @TenantId INT, @GoogleId NVARCHAR(255) = NULL, @Email NVARCHAR(255), @Name NVARCHAR(255), @PictureUrl NVARCHAR(MAX), @Role NVARCHAR(50), @CreatedDate DATETIME, @LastLoginDate DATETIME = NULL, @IsActive BIT AS 
BEGIN INSERT INTO corp.Users (TenantId, GoogleId, Email, Name, PictureUrl, Role, CreatedDate, LastLoginDate, IsActive) OUTPUT INSERTED.UserId VALUES (@TenantId, @GoogleId, @Email, @Name, @PictureUrl, @Role, @CreatedDate, @LastLoginDate, @IsActive); END
GO
CREATE OR ALTER PROCEDURE corp.sp_Users_Update @UserId INT, @Name NVARCHAR(255), @PictureUrl NVARCHAR(MAX), @Role NVARCHAR(50), @LastLoginDate DATETIME, @IsActive BIT AS 
BEGIN UPDATE corp.Users SET Name = @Name, PictureUrl = @PictureUrl, Role = @Role, LastLoginDate = @LastLoginDate, IsActive = @IsActive WHERE UserId = @UserId; END
GO

CREATE OR ALTER PROCEDURE corp.sp_UserAssociations_CheckExists @UserId INT, @TenantId INT AS 
BEGIN SELECT COUNT(1) FROM corp.UserAssociations WHERE UserId = @UserId AND TenantId = @TenantId; END
GO
CREATE OR ALTER PROCEDURE corp.sp_UserAssociations_Upsert @UserId INT, @TenantId INT, @Role NVARCHAR(50) AS 
BEGIN 
    IF EXISTS (SELECT 1 FROM corp.UserAssociations WHERE UserId = @UserId AND TenantId = @TenantId)
        UPDATE corp.UserAssociations SET Role = @Role WHERE UserId = @UserId AND TenantId = @TenantId
    ELSE
        INSERT INTO corp.UserAssociations (UserId, TenantId, Role) VALUES (@UserId, @TenantId, @Role);
END
GO
CREATE OR ALTER PROCEDURE corp.sp_UserAssociations_GetRole @UserId INT, @TenantId INT AS 
BEGIN SELECT Role FROM corp.UserAssociations WHERE UserId = @UserId AND TenantId = @TenantId; END
GO
CREATE OR ALTER PROCEDURE corp.sp_UserAssociations_Delete @UserId INT, @TenantId INT AS 
BEGIN DELETE FROM corp.UserAssociations WHERE UserId = @UserId AND TenantId = @TenantId; END
GO

-- AUDIT LOGS
CREATE OR ALTER PROCEDURE corp.sp_AuditLogs_Create @TenantId INT, @AssociationId INT, @UserId INT = NULL, @Action NVARCHAR(100), @Entity NVARCHAR(100), @EntityId INT = NULL, @IpAddress NVARCHAR(50) = NULL, @Timestamp DATETIME AS 
BEGIN INSERT INTO corp.AuditLogs (TenantId, AssociationId, UserId, Action, Entity, EntityId, IpAddress, Timestamp) OUTPUT INSERTED.AuditLogId VALUES (@TenantId, @AssociationId, @UserId, @Action, @Entity, @EntityId, @IpAddress, @Timestamp); END
GO
CREATE OR ALTER PROCEDURE corp.sp_AuditLogs_GetByTenantId @TenantId INT, @AssociationId INT AS 
BEGIN SELECT * FROM corp.AuditLogs WHERE TenantId = @TenantId AND AssociationId = @AssociationId ORDER BY Timestamp DESC; END
GO

-- SUBSCRIPTIONS
CREATE OR ALTER PROCEDURE corp.sp_SubscriptionPlans_GetAll AS 
BEGIN SELECT * FROM corp.SubscriptionPlans; END
GO
CREATE OR ALTER PROCEDURE corp.sp_Subscriptions_GetByAssociationId @AssociationId INT AS 
BEGIN
    SELECT s.*, a.TenantId, a.Name as AssociationName, p.Name as PlanName, p.BasePrice, p.PricePerAsset
    FROM corp.AssociationSubscriptions s
    JOIN corp.SubscriptionPlans p ON s.PlanId = p.PlanId
    JOIN corp.Associations a ON s.AssociationId = a.AssociationId
    WHERE s.AssociationId = @AssociationId;
END
GO
CREATE OR ALTER PROCEDURE corp.sp_Subscriptions_Upsert @AssociationId INT, @PlanId INT, @Status NVARCHAR(50), @NextBillingDate DATETIME AS 
BEGIN
    IF EXISTS (SELECT 1 FROM corp.AssociationSubscriptions WHERE AssociationId = @AssociationId)
        UPDATE corp.AssociationSubscriptions SET PlanId = @PlanId, Status = @Status, NextBillingDate = @NextBillingDate WHERE AssociationId = @AssociationId
    ELSE
        INSERT INTO corp.AssociationSubscriptions (AssociationId, PlanId, Status, NextBillingDate) VALUES (@AssociationId, @PlanId, @Status, @NextBillingDate);
END
GO
CREATE OR ALTER PROCEDURE corp.sp_SubscriptionPlans_Upsert @PlanId INT, @Name NVARCHAR(100), @BasePrice DECIMAL(18,2), @PricePerAsset DECIMAL(18,2), @IsActive BIT AS 
BEGIN
    IF EXISTS (SELECT 1 FROM corp.SubscriptionPlans WHERE PlanId = @PlanId)
        UPDATE corp.SubscriptionPlans SET Name = @Name, BasePrice = @BasePrice, PricePerAsset = @PricePerAsset, IsActive = @IsActive WHERE PlanId = @PlanId
    ELSE
        INSERT INTO corp.SubscriptionPlans (Name, BasePrice, PricePerAsset, IsActive) VALUES (@Name, @BasePrice, @PricePerAsset, @IsActive);
END
GO

-- REFRESH TOKENS
CREATE OR ALTER PROCEDURE corp.sp_RefreshTokens_GetByToken @Token NVARCHAR(MAX) AS 
BEGIN SELECT * FROM corp.RefreshTokens WHERE Token = @Token; END
GO
CREATE OR ALTER PROCEDURE corp.sp_RefreshTokens_Upsert @UserId INT, @Token NVARCHAR(MAX), @ExpiryDate DATETIME, @CreatedDate DATETIME AS 
BEGIN
    IF EXISTS (SELECT 1 FROM corp.RefreshTokens WHERE UserId = @UserId)
        UPDATE corp.RefreshTokens SET Token = @Token, ExpiryDate = @ExpiryDate WHERE UserId = @UserId
    ELSE
        INSERT INTO corp.RefreshTokens (UserId, Token, ExpiryDate, CreatedDate) VALUES (@UserId, @Token, @ExpiryDate, @CreatedDate);
END
GO
CREATE OR ALTER PROCEDURE corp.sp_RefreshTokens_Delete @UserId INT AS 
BEGIN DELETE FROM corp.RefreshTokens WHERE UserId = @UserId; END
GO
