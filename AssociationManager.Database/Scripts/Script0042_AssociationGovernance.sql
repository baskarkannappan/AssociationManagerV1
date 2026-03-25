-- Script0042_AssociationGovernance.sql
-- Association Profile, Committee, Bye-laws, Meetings, and Elections

-- 1. Association Profile
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'AssociationProfile' AND schema_id = SCHEMA_ID('assoc'))
BEGIN
    CREATE TABLE assoc.AssociationProfile (
        AssociationId INT PRIMARY KEY,
        RegistrationNumber NVARCHAR(100),
        RegistrationDate DATETIME,
        Address NVARCHAR(500),
        City NVARCHAR(100),
        State NVARCHAR(100),
        Pincode NVARCHAR(20),
        ContactEmail NVARCHAR(255),
        ContactPhone NVARCHAR(50),
        FOREIGN KEY (AssociationId) REFERENCES corp.Associations(AssociationId)
    );
END
GO

-- 2. Committee Roles
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'CommitteeRoles' AND schema_id = SCHEMA_ID('assoc'))
BEGIN
    CREATE TABLE assoc.CommitteeRoles (
        RoleId INT PRIMARY KEY IDENTITY(1,1),
        RoleName NVARCHAR(100) NOT NULL
    );
    
    -- Seed default roles
    INSERT INTO assoc.CommitteeRoles (RoleName) VALUES 
    ('President'), ('Vice President'), ('Secretary'), ('Treasurer'), ('Committee Member');
END
GO

-- 3. Committee Members
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'CommitteeMembers' AND schema_id = SCHEMA_ID('assoc'))
BEGIN
    CREATE TABLE assoc.CommitteeMembers (
        CommitteeMemberId INT PRIMARY KEY IDENTITY(1,1),
        AssociationId INT NOT NULL,
        MemberId INT NOT NULL,
        RoleId INT NOT NULL,
        StartDate DATETIME NOT NULL,
        EndDate DATETIME NULL,
        IsActive BIT DEFAULT 1,
        FOREIGN KEY (AssociationId) REFERENCES corp.Associations(AssociationId),
        FOREIGN KEY (MemberId) REFERENCES corp.Users(UserId),
        FOREIGN KEY (RoleId) REFERENCES assoc.CommitteeRoles(RoleId)
    );
END
GO

-- 4. Bye-laws
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'ByeLaws' AND schema_id = SCHEMA_ID('assoc'))
BEGIN
    CREATE TABLE assoc.ByeLaws (
        ByeLawId INT PRIMARY KEY IDENTITY(1,1),
        AssociationId INT NOT NULL,
        Title NVARCHAR(255) NOT NULL,
        Description NVARCHAR(MAX),
        EffectiveDate DATETIME NOT NULL,
        Version NVARCHAR(50),
        IsActive BIT DEFAULT 1,
        CreatedDate DATETIME DEFAULT GETUTCDATE(),
        FOREIGN KEY (AssociationId) REFERENCES corp.Associations(AssociationId)
    );
END
GO

-- 5. Meetings
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'Meetings' AND schema_id = SCHEMA_ID('assoc'))
BEGIN
    CREATE TABLE assoc.Meetings (
        MeetingId INT PRIMARY KEY IDENTITY(1,1),
        AssociationId INT NOT NULL,
        Title NVARCHAR(255) NOT NULL,
        MeetingDate DATETIME NOT NULL,
        Description NVARCHAR(MAX),
        CreatedBy INT NOT NULL,
        CreatedDate DATETIME DEFAULT GETUTCDATE(),
        FOREIGN KEY (AssociationId) REFERENCES corp.Associations(AssociationId),
        FOREIGN KEY (CreatedBy) REFERENCES corp.Users(UserId)
    );
END
GO

-- 6. Meeting Minutes
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'MeetingMinutes' AND schema_id = SCHEMA_ID('assoc'))
BEGIN
    CREATE TABLE assoc.MeetingMinutes (
        MinutesId INT PRIMARY KEY IDENTITY(1,1),
        MeetingId INT NOT NULL,
        Notes NVARCHAR(MAX),
        DocumentUrl NVARCHAR(MAX),
        CreatedDate DATETIME DEFAULT GETUTCDATE(),
        FOREIGN KEY (MeetingId) REFERENCES assoc.Meetings(MeetingId)
    );
END
GO

-- 7. Elections
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'Elections' AND schema_id = SCHEMA_ID('assoc'))
BEGIN
    CREATE TABLE assoc.Elections (
        ElectionId INT PRIMARY KEY IDENTITY(1,1),
        AssociationId INT NOT NULL,
        Title NVARCHAR(255) NOT NULL,
        StartDate DATETIME NOT NULL,
        EndDate DATETIME NOT NULL,
        IsActive BIT DEFAULT 1,
        FOREIGN KEY (AssociationId) REFERENCES corp.Associations(AssociationId)
    );
END
GO

-- 8. Candidates
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'Candidates' AND schema_id = SCHEMA_ID('assoc'))
BEGIN
    CREATE TABLE assoc.Candidates (
        CandidateId INT PRIMARY KEY IDENTITY(1,1),
        ElectionId INT NOT NULL,
        MemberId INT NOT NULL,
        FOREIGN KEY (ElectionId) REFERENCES assoc.Elections(ElectionId),
        FOREIGN KEY (MemberId) REFERENCES corp.Users(UserId)
    );
END
GO

-- 9. Votes
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'Votes' AND schema_id = SCHEMA_ID('assoc'))
BEGIN
    CREATE TABLE assoc.Votes (
        VoteId INT PRIMARY KEY IDENTITY(1,1),
        ElectionId INT NOT NULL,
        MemberId INT NOT NULL,
        CandidateId INT NOT NULL,
        VoteDate DATETIME DEFAULT GETUTCDATE(),
        FOREIGN KEY (ElectionId) REFERENCES assoc.Elections(ElectionId),
        FOREIGN KEY (MemberId) REFERENCES corp.Users(UserId),
        FOREIGN KEY (CandidateId) REFERENCES assoc.Candidates(CandidateId),
        CONSTRAINT UQ_Election_Member UNIQUE (ElectionId, MemberId)
    );
END
GO
