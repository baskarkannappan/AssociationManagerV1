using AssociationManager.Data.Interfaces;
using AssociationManager.Shared.Models;
using Dapper;
using System.Collections.Generic;
using System.Data;
using System.Threading.Tasks;

namespace AssociationManager.Data.Repositories;

public class GovernanceRepository : IGovernanceRepository
{
    private readonly DbConnectionFactory _dbConnectionFactory;

    public GovernanceRepository(DbConnectionFactory dbConnectionFactory)
    {
        _dbConnectionFactory = dbConnectionFactory;
    }

    // Profile
    public async Task<AssociationProfile?> GetProfileAsync(int associationId)
    {
        using var connection = _dbConnectionFactory.CreateConnection();
        return await connection.QueryFirstOrDefaultAsync<AssociationProfile>(
            "SELECT * FROM assoc.AssociationProfile WHERE AssociationId = @associationId",
            new { associationId });
    }

    public async Task<bool> UpdateProfileAsync(AssociationProfile profile)
    {
        using var connection = _dbConnectionFactory.CreateConnection();
        var sql = @"
            IF EXISTS (SELECT 1 FROM assoc.AssociationProfile WHERE AssociationId = @AssociationId)
            BEGIN
                UPDATE assoc.AssociationProfile SET 
                    RegistrationNumber = @RegistrationNumber, 
                    RegistrationDate = @RegistrationDate,
                    Address = @Address, City = @City, State = @State, Pincode = @Pincode,
                    ContactEmail = @ContactEmail, ContactPhone = @ContactPhone,
                    Logo = @Logo
                WHERE AssociationId = @AssociationId
            END
            ELSE
            BEGIN
                INSERT INTO assoc.AssociationProfile (AssociationId, RegistrationNumber, RegistrationDate, Address, City, State, Pincode, ContactEmail, ContactPhone, Logo)
                VALUES (@AssociationId, @RegistrationNumber, @RegistrationDate, @Address, @City, @State, @Pincode, @ContactEmail, @ContactPhone, @Logo)
            END";
        return await connection.ExecuteAsync(sql, profile) > 0;
    }

    // Committee
    public async Task<IEnumerable<CommitteeRole>> GetCommitteeRolesAsync()
    {
        using var connection = _dbConnectionFactory.CreateConnection();
        return await connection.QueryAsync<CommitteeRole>("SELECT * FROM assoc.CommitteeRoles");
    }

    public async Task<IEnumerable<CommitteeMember>> GetCommitteeMembersAsync(int associationId, bool activeOnly = true)
    {
        using var connection = _dbConnectionFactory.CreateConnection();
        var sql = @"
            SELECT cm.*, COALESCE(cm.MemberName, u.Name) as MemberName, cr.RoleName 
            FROM assoc.CommitteeMembers cm
            LEFT JOIN corp.Users u ON cm.MemberId = u.UserId
            JOIN assoc.CommitteeRoles cr ON cm.RoleId = cr.RoleId
            WHERE cm.AssociationId = @associationId";
        if (activeOnly) sql += " AND cm.IsActive = 1";
        return await connection.QueryAsync<CommitteeMember>(sql, new { associationId });
    }

    public async Task<int> AddCommitteeMemberAsync(CommitteeMember member)
    {
        using var connection = _dbConnectionFactory.CreateConnection();
        var sql = @"
            INSERT INTO assoc.CommitteeMembers (AssociationId, MemberId, MemberName, RoleId, StartDate, EndDate, IsActive)
            VALUES (@AssociationId, @MemberId, @MemberName, @RoleId, @StartDate, @EndDate, @IsActive);
            SELECT SCOPE_IDENTITY();";
        return await connection.ExecuteScalarAsync<int>(sql, member);
    }

    public async Task<bool> UpdateCommitteeMemberAsync(CommitteeMember member)
    {
        using var connection = _dbConnectionFactory.CreateConnection();
        var sql = "UPDATE assoc.CommitteeMembers SET RoleId = @RoleId, StartDate = @StartDate, EndDate = @EndDate, IsActive = @IsActive WHERE CommitteeMemberId = @CommitteeMemberId";
        return await connection.ExecuteAsync(sql, member) > 0;
    }

    // Bye-laws
    public async Task<IEnumerable<ByeLaw>> GetByeLawsAsync(int associationId, bool activeOnly = true)
    {
        using var connection = _dbConnectionFactory.CreateConnection();
        var sql = "SELECT * FROM assoc.ByeLaws WHERE AssociationId = @associationId";
        if (activeOnly) sql += " AND IsActive = 1";
        return await connection.QueryAsync<ByeLaw>(sql, new { associationId });
    }

    public async Task<int> CreateByeLawAsync(ByeLaw byeLaw)
    {
        using var connection = _dbConnectionFactory.CreateConnection();
        var sql = @"
            INSERT INTO assoc.ByeLaws (AssociationId, Title, Description, EffectiveDate, Version, IsActive, DocumentContent, FileName, ContentType)
            VALUES (@AssociationId, @Title, @Description, @EffectiveDate, @Version, @IsActive, @DocumentContent, @FileName, @ContentType);
            SELECT SCOPE_IDENTITY();";
        return await connection.ExecuteScalarAsync<int>(sql, byeLaw);
    }

    public async Task<bool> UpdateByeLawAsync(ByeLaw byeLaw)
    {
        using var connection = _dbConnectionFactory.CreateConnection();
        var sql = @"
            UPDATE assoc.ByeLaws SET 
                Title = @Title, 
                Description = @Description, 
                EffectiveDate = @EffectiveDate, 
                Version = @Version, 
                IsActive = @IsActive,
                DocumentContent = @DocumentContent,
                FileName = @FileName,
                ContentType = @ContentType
            WHERE ByeLawId = @ByeLawId";
        return await connection.ExecuteAsync(sql, byeLaw) > 0;
    }

    public async Task<bool> DeleteByeLawAsync(int id)
    {
        using var connection = _dbConnectionFactory.CreateConnection();
        return await connection.ExecuteAsync("DELETE FROM assoc.ByeLaws WHERE ByeLawId = @id", new { id }) > 0;
    }

    public async Task<ByeLaw?> GetByeLawByIdAsync(int id)
    {
        using var connection = _dbConnectionFactory.CreateConnection();
        return await connection.QueryFirstOrDefaultAsync<ByeLaw>("SELECT * FROM assoc.ByeLaws WHERE ByeLawId = @id", new { id });
    }

    // Meetings
    public async Task<IEnumerable<Meeting>> GetMeetingsAsync(int associationId)
    {
        using var connection = _dbConnectionFactory.CreateConnection();
        return await connection.QueryAsync<Meeting>("SELECT * FROM assoc.Meetings WHERE AssociationId = @associationId", new { associationId });
    }

    public async Task<int> CreateMeetingAsync(Meeting meeting)
    {
        using var connection = _dbConnectionFactory.CreateConnection();
        var sql = @"
            INSERT INTO assoc.Meetings (AssociationId, Title, MeetingDate, Description, CreatedBy)
            VALUES (@AssociationId, @Title, @MeetingDate, @Description, @CreatedBy);
            SELECT SCOPE_IDENTITY();";
        return await connection.ExecuteScalarAsync<int>(sql, meeting);
    }

    public async Task<int> AddMeetingMinutesAsync(MeetingMinutes minutes)
    {
        using var connection = _dbConnectionFactory.CreateConnection();
        var sql = @"
            INSERT INTO assoc.MeetingMinutes (MeetingId, Notes, DocumentUrl)
            VALUES (@MeetingId, @Notes, @DocumentUrl);
            SELECT SCOPE_IDENTITY();";
        return await connection.ExecuteScalarAsync<int>(sql, minutes);
    }

    public async Task<IEnumerable<MeetingMinutes>> GetMeetingMinutesAsync(int meetingId)
    {
        using var connection = _dbConnectionFactory.CreateConnection();
        return await connection.QueryAsync<MeetingMinutes>("SELECT * FROM assoc.MeetingMinutes WHERE MeetingId = @meetingId", new { meetingId });
    }

    // Elections
    public async Task<IEnumerable<Election>> GetElectionsAsync(int associationId, bool activeOnly = true)
    {
        using var connection = _dbConnectionFactory.CreateConnection();
        var sql = "SELECT * FROM assoc.Elections WHERE AssociationId = @associationId";
        if (activeOnly) sql += " AND IsActive = 1";
        return await connection.QueryAsync<Election>(sql, new { associationId });
    }

    public async Task<int> CreateElectionAsync(Election election)
    {
        using var connection = _dbConnectionFactory.CreateConnection();
        var sql = @"INSERT INTO assoc.Elections (AssociationId, Title, StartDate, EndDate, IsActive) VALUES (@AssociationId, @Title, @StartDate, @EndDate, @IsActive); SELECT SCOPE_IDENTITY();";
        return await connection.ExecuteScalarAsync<int>(sql, election);
    }

    public async Task<int> AddCandidateAsync(Candidate candidate)
    {
        using var connection = _dbConnectionFactory.CreateConnection();
        var sql = @"INSERT INTO assoc.Candidates (ElectionId, MemberId) VALUES (@ElectionId, @MemberId); SELECT SCOPE_IDENTITY();";
        return await connection.ExecuteScalarAsync<int>(sql, candidate);
    }

    public async Task<bool> CastVoteAsync(Vote vote)
    {
        using var connection = _dbConnectionFactory.CreateConnection();
        var sql = "INSERT INTO assoc.Votes (ElectionId, MemberId, CandidateId) VALUES (@ElectionId, @MemberId, @CandidateId)";
        try {
            return await connection.ExecuteAsync(sql, vote) > 0;
        } catch {
            return false; // Constraint violation
        }
    }

    public async Task<IEnumerable<ElectionResult>> GetElectionResultsAsync(int electionId)
    {
        using var connection = _dbConnectionFactory.CreateConnection();
        var sql = @"
            SELECT u.Name as CandidateName, COUNT(v.VoteId) as VoteCount
            FROM assoc.Candidates c
            JOIN corp.Users u ON c.MemberId = u.UserId
            LEFT JOIN assoc.Votes v ON c.CandidateId = v.CandidateId
            WHERE c.ElectionId = @electionId
            GROUP BY u.Name";
        return await connection.QueryAsync<ElectionResult>(sql, new { electionId });
    }

    public async Task<bool> HasUserVotedAsync(int electionId, int memberId)
    {
        using var connection = _dbConnectionFactory.CreateConnection();
        return await connection.ExecuteScalarAsync<int>("SELECT COUNT(1) FROM assoc.Votes WHERE ElectionId = @electionId AND MemberId = @memberId", new { electionId, memberId }) > 0;
    }
}
