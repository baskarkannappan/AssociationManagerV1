-- Ensure we have two tenants
IF NOT EXISTS (SELECT 1 FROM Tenants WHERE Name = 'Association A')
    INSERT INTO Tenants (Name, CreatedDate) VALUES ('Association A', GETUTCDATE());

IF NOT EXISTS (SELECT 1 FROM Tenants WHERE Name = 'Association B')
    INSERT INTO Tenants (Name, CreatedDate) VALUES ('Association B', GETUTCDATE());

DECLARE @TenantA INT = (SELECT TOP 1 TenantId FROM Tenants WHERE Name = 'Association A');
DECLARE @TenantB INT = (SELECT TOP 1 TenantId FROM Tenants WHERE Name = 'Association B');

-- Create a sample user
IF NOT EXISTS (SELECT 1 FROM Users WHERE Email = 'multi@tenant.com')
    INSERT INTO Users (Email, Name, Role, TenantId, GoogleId, IsActive, CreatedDate)
    VALUES ('multi@tenant.com', 'Multi Tenant User', 'User', @TenantA, 'sample-google-id-123', 1, GETUTCDATE());

DECLARE @UserId INT = (SELECT UserId FROM Users WHERE Email = 'multi@tenant.com');

-- Map user to multiple tenants in UserAssociations
IF NOT EXISTS (SELECT 1 FROM UserAssociations WHERE UserId = @UserId AND TenantId = @TenantA)
    INSERT INTO UserAssociations (UserId, TenantId, Role, CreatedDate)
    VALUES (@UserId, @TenantA, 'User', GETUTCDATE());

IF NOT EXISTS (SELECT 1 FROM UserAssociations WHERE UserId = @UserId AND TenantId = @TenantB)
    INSERT INTO UserAssociations (UserId, TenantId, Role, CreatedDate)
    VALUES (@UserId, @TenantB, 'User', GETUTCDATE());

-- Also ensure we have an Association record for each tenant
IF NOT EXISTS (SELECT 1 FROM Associations WHERE TenantId = @TenantA)
    INSERT INTO Associations (TenantId, Name, CreatedDate) VALUES (@TenantA, 'Association A Main', GETUTCDATE());

IF NOT EXISTS (SELECT 1 FROM Associations WHERE TenantId = @TenantB)
    INSERT INTO Associations (TenantId, Name, CreatedDate) VALUES (@TenantB, 'Association B Main', GETUTCDATE());
