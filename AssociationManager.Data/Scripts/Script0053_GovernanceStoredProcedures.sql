-- Governance Stored Procedures

-- 1. Profile
CREATE OR ALTER PROCEDURE assoc.sp_AssociationProfile_Get
    @AssociationId INT
AS
BEGIN
    SELECT * FROM assoc.AssociationProfile WHERE AssociationId = @AssociationId;
END;
GO

CREATE OR ALTER PROCEDURE assoc.sp_AssociationProfile_Upsert
    @AssociationId INT,
    @RegistrationNumber NVARCHAR(100),
    @RegistrationDate DATETIME2,
    @Address NVARCHAR(MAX),
    @City NVARCHAR(100),
    @State NVARCHAR(100),
    @Pincode NVARCHAR(20),
    @ContactEmail NVARCHAR(255),
    @ContactPhone NVARCHAR(50),
    @Logo NVARCHAR(MAX) = NULL
AS
BEGIN
    IF EXISTS (SELECT 1 FROM assoc.AssociationProfile WHERE AssociationId = @AssociationId)
    BEGIN
        UPDATE assoc.AssociationProfile SET 
            RegistrationNumber = @RegistrationNumber, 
            RegistrationDate = @RegistrationDate,
            Address = @Address, City = @City, State = @State, Pincode = @Pincode,
            ContactEmail = @ContactEmail, ContactPhone = @ContactPhone,
            Logo = @Logo
        WHERE AssociationId = @AssociationId;
    END
    ELSE
    BEGIN
        INSERT INTO assoc.AssociationProfile (AssociationId, RegistrationNumber, RegistrationDate, Address, City, State, Pincode, ContactEmail, ContactPhone, Logo)
        VALUES (@AssociationId, @RegistrationNumber, @RegistrationDate, @Address, @City, @State, @Pincode, @ContactEmail, @ContactPhone, @Logo);
    END
END;
GO

-- 2. Committee
CREATE OR ALTER PROCEDURE assoc.sp_CommitteeRoles_List
AS
BEGIN
    SELECT * FROM assoc.CommitteeRoles;
END;
GO

CREATE OR ALTER PROCEDURE assoc.sp_CommitteeMembers_List
    @AssociationId INT,
    @ActiveOnly BIT = 1
AS
BEGIN
    SELECT cm.*, COALESCE(cm.MemberName, u.Name) as MemberName, cr.RoleName 
    FROM assoc.CommitteeMembers cm
    LEFT JOIN corp.Users u ON cm.MemberId = u.UserId
    JOIN assoc.CommitteeRoles cr ON cm.RoleId = cr.RoleId
    WHERE cm.AssociationId = @AssociationId
    AND (@ActiveOnly = 0 OR cm.IsActive = 1);
END;
GO

CREATE OR ALTER PROCEDURE assoc.sp_CommitteeMembers_Insert
    @AssociationId INT,
    @MemberId INT,
    @MemberName NVARCHAR(255) = NULL,
    @RoleId INT,
    @StartDate DATETIME2,
    @EndDate DATETIME2 = NULL,
    @IsActive BIT
AS
BEGIN
    INSERT INTO assoc.CommitteeMembers (AssociationId, MemberId, MemberName, RoleId, StartDate, EndDate, IsActive)
    VALUES (@AssociationId, @MemberId, @MemberName, @RoleId, @StartDate, @EndDate, @IsActive);
    SELECT SCOPE_IDENTITY();
END;
GO

CREATE OR ALTER PROCEDURE assoc.sp_CommitteeMembers_Update
    @CommitteeMemberId INT,
    @MemberName NVARCHAR(255) = NULL,
    @RoleId INT,
    @StartDate DATETIME2,
    @EndDate DATETIME2 = NULL,
    @IsActive BIT
AS
BEGIN
    UPDATE assoc.CommitteeMembers 
    SET RoleId = @RoleId, 
        MemberName = @MemberName, 
        StartDate = @StartDate, 
        EndDate = @EndDate, 
        IsActive = @IsActive 
    WHERE CommitteeMemberId = @CommitteeMemberId;
END;
GO

-- 3. Bye-laws
CREATE OR ALTER PROCEDURE assoc.sp_ByeLaws_List
    @AssociationId INT,
    @ActiveOnly BIT = 1
AS
BEGIN
    SELECT * FROM assoc.ByeLaws 
    WHERE AssociationId = @AssociationId
    AND (@ActiveOnly = 0 OR IsActive = 1);
END;
GO

CREATE OR ALTER PROCEDURE assoc.sp_ByeLaws_Insert
    @AssociationId INT,
    @Title NVARCHAR(200),
    @Description NVARCHAR(MAX),
    @EffectiveDate DATETIME2,
    @Version NVARCHAR(50),
    @IsActive BIT,
    @DocumentContent VARBINARY(MAX) = NULL,
    @FileName NVARCHAR(255) = NULL,
    @ContentType NVARCHAR(100) = NULL
AS
BEGIN
    INSERT INTO assoc.ByeLaws (AssociationId, Title, Description, EffectiveDate, Version, IsActive, DocumentContent, FileName, ContentType)
    VALUES (@AssociationId, @Title, @Description, @EffectiveDate, @Version, @IsActive, @DocumentContent, @FileName, @ContentType);
    SELECT SCOPE_IDENTITY();
END;
GO

CREATE OR ALTER PROCEDURE assoc.sp_ByeLaws_Update
    @ByeLawId INT,
    @Title NVARCHAR(200),
    @Description NVARCHAR(MAX),
    @EffectiveDate DATETIME2,
    @Version NVARCHAR(50),
    @IsActive BIT,
    @DocumentContent VARBINARY(MAX) = NULL,
    @FileName NVARCHAR(255) = NULL,
    @ContentType NVARCHAR(100) = NULL
AS
BEGIN
    UPDATE assoc.ByeLaws SET 
        Title = @Title, 
        Description = @Description, 
        EffectiveDate = @EffectiveDate, 
        Version = @Version, 
        IsActive = @IsActive,
        DocumentContent = @DocumentContent,
        FileName = @FileName,
        ContentType = @ContentType
    WHERE ByeLawId = @ByeLawId;
END;
GO

CREATE OR ALTER PROCEDURE assoc.sp_ByeLaws_Delete
    @id INT
AS
BEGIN
    DELETE FROM assoc.ByeLaws WHERE ByeLawId = @id;
END;
GO

CREATE OR ALTER PROCEDURE assoc.sp_ByeLaws_GetById
    @id INT
AS
BEGIN
    SELECT * FROM assoc.ByeLaws WHERE ByeLawId = @id;
END;
GO

-- 4. Meetings
CREATE OR ALTER PROCEDURE assoc.sp_Meetings_List
    @AssociationId INT
AS
BEGIN
    SELECT * FROM assoc.Meetings WHERE AssociationId = @AssociationId;
END;
GO

CREATE OR ALTER PROCEDURE assoc.sp_Meetings_Insert
    @AssociationId INT,
    @Title NVARCHAR(200),
    @MeetingDate DATETIME2,
    @Description NVARCHAR(MAX),
    @CreatedBy INT
AS
BEGIN
    INSERT INTO assoc.Meetings (AssociationId, Title, MeetingDate, Description, CreatedBy)
    VALUES (@AssociationId, @Title, @MeetingDate, @Description, @CreatedBy);
    SELECT SCOPE_IDENTITY();
END;
GO

CREATE OR ALTER PROCEDURE assoc.sp_MeetingMinutes_Insert
    @MeetingId INT,
    @Notes NVARCHAR(MAX),
    @DocumentUrl NVARCHAR(MAX) = NULL
AS
BEGIN
    INSERT INTO assoc.MeetingMinutes (MeetingId, Notes, DocumentUrl)
    VALUES (@MeetingId, @Notes, @DocumentUrl);
    SELECT SCOPE_IDENTITY();
END;
GO

CREATE OR ALTER PROCEDURE assoc.sp_MeetingMinutes_List
    @MeetingId INT
AS
BEGIN
    SELECT * FROM assoc.MeetingMinutes WHERE MeetingId = @MeetingId;
END;
GO

CREATE OR ALTER PROCEDURE assoc.sp_UserAssociations_List
AS
BEGIN
    SELECT * FROM assoc.UserAssociations;
END;
GO

CREATE OR ALTER PROCEDURE assoc.sp_BillingBatches_UpdateStatus
    @Id INT,
    @Status NVARCHAR(50),
    @TenantId INT,
    @AssociationId INT
AS
BEGIN
    UPDATE assoc.BillingBatches 
    SET Status = @Status 
    WHERE BillingBatchId = @Id 
    AND TenantId = @TenantId 
    AND AssociationId = @AssociationId;
END;
GO
CREATE OR ALTER PROCEDURE assoc.sp_Elections_List
    @AssociationId INT,
    @ActiveOnly BIT = 1
AS
BEGIN
    SELECT * FROM assoc.Elections 
    WHERE AssociationId = @AssociationId
    AND (@ActiveOnly = 0 OR IsActive = 1);
END;
GO

CREATE OR ALTER PROCEDURE assoc.sp_Elections_Insert
    @AssociationId INT,
    @Title NVARCHAR(200),
    @StartDate DATETIME2,
    @EndDate DATETIME2,
    @IsActive BIT
AS
BEGIN
    INSERT INTO assoc.Elections (AssociationId, Title, StartDate, EndDate, IsActive) 
    VALUES (@AssociationId, @Title, @StartDate, @EndDate, @IsActive);
    SELECT SCOPE_IDENTITY();
END;
GO

CREATE OR ALTER PROCEDURE assoc.sp_Candidates_Insert
    @ElectionId INT,
    @MemberId INT
AS
BEGIN
    INSERT INTO assoc.Candidates (ElectionId, MemberId) VALUES (@ElectionId, @MemberId);
    SELECT SCOPE_IDENTITY();
END;
GO

CREATE OR ALTER PROCEDURE assoc.sp_Votes_Insert
    @ElectionId INT,
    @MemberId INT,
    @CandidateId INT
AS
BEGIN
    INSERT INTO assoc.Votes (ElectionId, MemberId, CandidateId) VALUES (@ElectionId, @MemberId, @CandidateId);
END;
GO

CREATE OR ALTER PROCEDURE assoc.sp_ElectionResults_Get
    @ElectionId INT
AS
BEGIN
    SELECT u.Name as CandidateName, COUNT(v.VoteId) as VoteCount
    FROM assoc.Candidates c
    JOIN corp.Users u ON c.MemberId = u.UserId
    LEFT JOIN assoc.Votes v ON c.CandidateId = v.CandidateId
    WHERE c.ElectionId = @ElectionId
    GROUP BY u.Name;
END;
GO

CREATE OR ALTER PROCEDURE assoc.sp_Votes_Check
    @ElectionId INT,
    @MemberId INT
AS
BEGIN
    SELECT COUNT(1) FROM assoc.Votes WHERE ElectionId = @ElectionId AND MemberId = @MemberId;
END;
GO
