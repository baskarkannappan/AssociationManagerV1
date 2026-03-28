-- Script0055_CleanupUserRoles.sql
-- This script cleans up the contaminated Role column in both corp and assoc schemas.
-- It ensures that only the highest single role is preserved in the base Users table.

-- 1. Clean corp.Users
UPDATE corp.Users
SET Role = 
    CASE 
        WHEN Role LIKE '%PlatformAdmin%' THEN 'PlatformAdmin'
        WHEN Role LIKE '%SystemAdmin%' THEN 'SystemAdmin'
        WHEN Role LIKE '%GlobalUserManager%' THEN 'GlobalUserManager'
        WHEN Role LIKE '%CorporateManager%' THEN 'CorporateManager'
        WHEN Role LIKE '%AssociationAdmin%' THEN 'AssociationAdmin'
        WHEN Role LIKE '%Resident%' THEN 'Resident'
        ELSE Role
    END
WHERE Role LIKE '%,%';

-- 2. Clean assoc.Users
UPDATE assoc.Users
SET Role = 
    CASE 
        WHEN Role LIKE '%SystemAdmin%' THEN 'SystemAdmin'
        WHEN Role LIKE '%PlatformAdmin%' THEN 'PlatformAdmin'
        WHEN Role LIKE '%AssociationAdmin%' THEN 'AssociationAdmin'
        WHEN Role LIKE '%AssetManager%' THEN 'AssetManager'
        WHEN Role LIKE '%UserManager%' THEN 'UserManager'
        WHEN Role LIKE '%FinanceManager%' THEN 'FinanceManager'
        WHEN Role LIKE '%Resident%' THEN 'Resident'
        ELSE Role
    END
WHERE Role LIKE '%,%';

-- 3. Specific fix for reported user myassociationmanager005@gmail.com
-- The user reported this user is a resident, but they were acting as AssociationAdmin.
-- We ensure their base role in the Users table is 'Resident'.
-- If they have an explicit mapping in UserAssociations, that will still grant them the mapping role in that context.

UPDATE corp.Users SET Role = 'Resident' WHERE Email = 'myassociationmanager005@gmail.com';
UPDATE assoc.Users SET Role = 'Resident' WHERE Email = 'myassociationmanager005@gmail.com';

-- 4. Invalidate contaminated role in UserAssociations if any (just in case)
UPDATE assoc.UserAssociations
SET Role = 'Resident'
WHERE Role LIKE '%,%' AND Role LIKE '%Resident%';

UPDATE corp.UserAssociations
SET Role = 'Resident'
WHERE Role LIKE '%,%' AND Role LIKE '%Resident%';
