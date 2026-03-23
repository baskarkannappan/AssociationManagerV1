-- PROVISION SYSTEM ADMINS INTO ASSOC SCHEMA
-- Run this if you want to manually seed specific users from Corporate to Association pool

INSERT INTO assoc.Users (TenantId, GoogleId, Email, Name, PictureUrl, Role, CreatedDate, LastLoginDate, IsActive)
SELECT 
    TenantId, 
    GoogleId, 
    Email, 
    Name, 
    PictureUrl, 
    Role, 
    GETUTCDATE(), 
    LastLoginDate, 
    IsActive
FROM corp.Users
WHERE Role IN ('SystemAdmin', 'PlatformAdmin')
AND Email NOT IN (SELECT Email FROM assoc.Users);

-- Verify
SELECT * FROM assoc.Users;
