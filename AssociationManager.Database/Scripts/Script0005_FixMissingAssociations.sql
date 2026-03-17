-- Link all existing users to their primary tenant if not already linked
INSERT INTO UserAssociations (UserId, TenantId, Role, CreatedDate)
SELECT UserId, TenantId, Role, GETUTCDATE()
FROM Users u
WHERE NOT EXISTS (
    SELECT 1 FROM UserAssociations ua 
    WHERE ua.UserId = u.UserId 
    AND ua.TenantId = u.TenantId
);

-- Ensure we have sample data for everyone to switch to
IF NOT EXISTS (SELECT 1 FROM UserAssociations WHERE UserId = (SELECT TOP 1 UserId FROM Users ORDER BY UserId DESC) AND TenantId = (SELECT TOP 1 TenantId FROM Tenants ORDER BY TenantId DESC))
BEGIN
    INSERT INTO UserAssociations (UserId, TenantId, Role)
    SELECT u.UserId, t.TenantId, u.Role
    FROM Users u, Tenants t
    WHERE NOT EXISTS (SELECT 1 FROM UserAssociations ua WHERE ua.UserId = u.UserId AND ua.TenantId = t.TenantId);
END
