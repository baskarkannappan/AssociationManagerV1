-- Script0043_GovernanceEnhancements.sql
-- 1. Add Logo to AssociationProfile
IF NOT EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID('assoc.AssociationProfile') AND name = 'Logo')
BEGIN
    ALTER TABLE assoc.AssociationProfile ADD Logo VARBINARY(MAX) NULL;
END
GO

-- 2. Add Document storage to ByeLaws
IF NOT EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID('assoc.ByeLaws') AND name = 'DocumentContent')
BEGIN
    ALTER TABLE assoc.ByeLaws ADD DocumentContent VARBINARY(MAX) NULL;
    ALTER TABLE assoc.ByeLaws ADD FileName NVARCHAR(255) NULL;
    ALTER TABLE assoc.ByeLaws ADD ContentType NVARCHAR(100) NULL;
END
GO

-- 3. Update CommitteeMembers for free-text name
IF NOT EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID('assoc.CommitteeMembers') AND name = 'MemberName')
BEGIN
    ALTER TABLE assoc.CommitteeMembers ADD MemberName NVARCHAR(255) NULL;
    
    -- Make MemberId nullable so we can use MemberName instead
    ALTER TABLE assoc.CommitteeMembers ALTER COLUMN MemberId INT NULL;
END
GO
