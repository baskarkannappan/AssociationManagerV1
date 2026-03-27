-- Script0051_FixResidentMapping.sql
-- Fix the invalid TenantId (AssociationId) for residents who were defaulted to 1

PRINT 'Fixing resident association mapping for myassociationmanager005@gmail.com...'
GO

-- 1. Identify and fix the user myassociationmanager005@gmail.com
-- We found their data is in AssociationId 4013
UPDATE assoc.Users 
SET TenantId = 4013 
WHERE Email = 'myassociationmanager005@gmail.com' 
AND (TenantId = 1 OR TenantId = 0);

-- 2. General fix for any other residents who might be stranded on ID 1
-- Update their TenantId to match their first found occupancy association
UPDATE u
SET u.TenantId = o.AssociationId
FROM assoc.Users u
INNER JOIN assoc.Persons p ON u.Email = p.Email
INNER JOIN assoc.Occupancy o ON p.PersonId = o.PersonId
WHERE u.Role = 'Resident' 
AND (u.TenantId = 1 OR u.TenantId = 0)
AND o.AssociationId IS NOT NULL;

PRINT 'Script 0051 Complete.'
GO
