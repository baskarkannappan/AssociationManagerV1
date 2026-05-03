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
            "assoc.sp_AssociationProfile_Get",
            new { AssociationId = associationId },
            commandType: CommandType.StoredProcedure);
    }

    public async Task<bool> UpdateProfileAsync(AssociationProfile profile)
    {
        using var connection = _dbConnectionFactory.CreateConnection();
        var parameters = new DynamicParameters();
        parameters.Add("@AssociationId", profile.AssociationId);
        parameters.Add("@RegistrationNumber", profile.RegistrationNumber);
        parameters.Add("@RegistrationDate", profile.RegistrationDate);
        parameters.Add("@Address", profile.Address);
        parameters.Add("@City", profile.City);
        parameters.Add("@State", profile.State);
        parameters.Add("@Pincode", profile.Pincode);
        parameters.Add("@ContactEmail", profile.ContactEmail);
        parameters.Add("@ContactPhone", profile.ContactPhone);
        parameters.Add("@Logo", profile.Logo, DbType.Binary);

        return await connection.ExecuteAsync(
            "assoc.sp_AssociationProfile_Upsert",
            parameters,
            commandType: CommandType.StoredProcedure) > 0;
    }

    // Committee
    public async Task<IEnumerable<CommitteeRole>> GetCommitteeRolesAsync()
    {
        using var connection = _dbConnectionFactory.CreateConnection();
        return await connection.QueryAsync<CommitteeRole>(
            "assoc.sp_CommitteeRoles_List",
            commandType: CommandType.StoredProcedure);
    }

    public async Task<IEnumerable<CommitteeMember>> GetCommitteeMembersAsync(int associationId, bool activeOnly = true)
    {
        using var connection = _dbConnectionFactory.CreateConnection();
        return await connection.QueryAsync<CommitteeMember>(
            "assoc.sp_CommitteeMembers_List",
            new { AssociationId = associationId, ActiveOnly = activeOnly },
            commandType: CommandType.StoredProcedure);
    }

    public async Task<int> AddCommitteeMemberAsync(CommitteeMember member)
    {
        using var connection = _dbConnectionFactory.CreateConnection();
        return await connection.ExecuteScalarAsync<int>(
            "assoc.sp_CommitteeMembers_Insert",
            new
            {
                member.AssociationId,
                member.MemberId,
                member.MemberName,
                member.RoleId,
                StartDate = SafeDate(member.StartDate),
                EndDate = member.EndDate.HasValue ? SafeDate(member.EndDate.Value) : (DateTime?)null,
                member.IsActive
            },
            commandType: CommandType.StoredProcedure);
    }

    public async Task<bool> UpdateCommitteeMemberAsync(CommitteeMember member)
    {
        using var connection = _dbConnectionFactory.CreateConnection();
        return await connection.ExecuteAsync(
            "assoc.sp_CommitteeMembers_Update",
            new
            {
                member.CommitteeMemberId,
                member.MemberName,
                member.RoleId,
                StartDate = SafeDate(member.StartDate),
                EndDate = member.EndDate.HasValue ? SafeDate(member.EndDate.Value) : (DateTime?)null,
                member.IsActive
            },
            commandType: CommandType.StoredProcedure) > 0;
    }

    // Bye-laws
    public async Task<IEnumerable<ByeLaw>> GetByeLawsAsync(int associationId, bool activeOnly = true)
    {
        using var connection = _dbConnectionFactory.CreateConnection();
        return await connection.QueryAsync<ByeLaw>(
            "assoc.sp_ByeLaws_List",
            new { AssociationId = associationId, ActiveOnly = activeOnly },
            commandType: CommandType.StoredProcedure);
    }

    public async Task<int> CreateByeLawAsync(ByeLaw byeLaw)
    {
        using var connection = _dbConnectionFactory.CreateConnection();
        return await connection.ExecuteScalarAsync<int>(
            "assoc.sp_ByeLaws_Insert",
            new
            {
                byeLaw.AssociationId,
                byeLaw.Title,
                byeLaw.Description,
                EffectiveDate = SafeDate(byeLaw.EffectiveDate),
                byeLaw.Version,
                byeLaw.IsActive,
                byeLaw.DocumentContent,
                byeLaw.FileName,
                byeLaw.ContentType
            },
            commandType: CommandType.StoredProcedure);
    }

    public async Task<bool> UpdateByeLawAsync(ByeLaw byeLaw)
    {
        using var connection = _dbConnectionFactory.CreateConnection();
        return await connection.ExecuteAsync(
            "assoc.sp_ByeLaws_Update",
            new
            {
                byeLaw.ByeLawId,
                byeLaw.Title,
                byeLaw.Description,
                EffectiveDate = SafeDate(byeLaw.EffectiveDate),
                byeLaw.Version,
                byeLaw.IsActive,
                byeLaw.DocumentContent,
                byeLaw.FileName,
                byeLaw.ContentType
            },
            commandType: CommandType.StoredProcedure) > 0;
    }

    public async Task<bool> DeleteByeLawAsync(int id)
    {
        using var connection = _dbConnectionFactory.CreateConnection();
        return await connection.ExecuteAsync(
            "assoc.sp_ByeLaws_Delete",
            new { id },
            commandType: CommandType.StoredProcedure) > 0;
    }

    public async Task<ByeLaw?> GetByeLawByIdAsync(int id)
    {
        using var connection = _dbConnectionFactory.CreateConnection();
        return await connection.QueryFirstOrDefaultAsync<ByeLaw>(
            "assoc.sp_ByeLaws_GetById",
            new { id },
            commandType: CommandType.StoredProcedure);
    }

    // Meetings
    public async Task<IEnumerable<Meeting>> GetMeetingsAsync(int associationId)
    {
        using var connection = _dbConnectionFactory.CreateConnection();
        return await connection.QueryAsync<Meeting>(
            "assoc.sp_Meetings_List",
            new { AssociationId = associationId },
            commandType: CommandType.StoredProcedure);
    }

    public async Task<int> CreateMeetingAsync(Meeting meeting)
    {
        using var connection = _dbConnectionFactory.CreateConnection();
        return await connection.ExecuteScalarAsync<int>(
            "assoc.sp_Meetings_Insert",
            new
            {
                meeting.AssociationId,
                meeting.Title,
                MeetingDate = SafeDate(meeting.MeetingDate),
                meeting.Description,
                meeting.CreatedBy
            },
            commandType: CommandType.StoredProcedure);
    }

    public async Task<int> AddMeetingMinutesAsync(MeetingMinutes minutes)
    {
        using var connection = _dbConnectionFactory.CreateConnection();
        return await connection.ExecuteScalarAsync<int>(
            "assoc.sp_MeetingMinutes_Insert",
            minutes,
            commandType: CommandType.StoredProcedure);
    }

    public async Task<IEnumerable<MeetingMinutes>> GetMeetingMinutesAsync(int meetingId)
    {
        using var connection = _dbConnectionFactory.CreateConnection();
        return await connection.QueryAsync<MeetingMinutes>(
            "assoc.sp_MeetingMinutes_List",
            new { MeetingId = meetingId },
            commandType: CommandType.StoredProcedure);
    }

    // Elections
    public async Task<IEnumerable<Election>> GetElectionsAsync(int associationId, bool activeOnly = true)
    {
        using var connection = _dbConnectionFactory.CreateConnection();
        return await connection.QueryAsync<Election>(
            "assoc.sp_Elections_List",
            new { AssociationId = associationId, ActiveOnly = activeOnly },
            commandType: CommandType.StoredProcedure);
    }

    public async Task<int> CreateElectionAsync(Election election)
    {
        using var connection = _dbConnectionFactory.CreateConnection();
        return await connection.ExecuteScalarAsync<int>(
            "assoc.sp_Elections_Insert",
            new
            {
                election.AssociationId,
                election.Title,
                StartDate = SafeDate(election.StartDate),
                EndDate = SafeDate(election.EndDate),
                election.IsActive
            },
            commandType: CommandType.StoredProcedure);
    }

    private DateTime SafeDate(DateTime date)
    {
        if (date < new DateTime(1753, 1, 1)) return DateTime.UtcNow;
        return date;
    }

    public async Task<int> AddCandidateAsync(Candidate candidate)
    {
        using var connection = _dbConnectionFactory.CreateConnection();
        return await connection.ExecuteScalarAsync<int>(
            "assoc.sp_Candidates_Insert",
            new { candidate.ElectionId, candidate.MemberId },
            commandType: CommandType.StoredProcedure);
    }

    public async Task<bool> CastVoteAsync(Vote vote)
    {
        using var connection = _dbConnectionFactory.CreateConnection();
        try {
            return await connection.ExecuteAsync(
                "assoc.sp_Votes_Insert",
                new { vote.ElectionId, vote.MemberId, vote.CandidateId },
                commandType: CommandType.StoredProcedure) > 0;
        } catch {
            return false; // Constraint violation
        }
    }

    public async Task<IEnumerable<ElectionResult>> GetElectionResultsAsync(int electionId)
    {
        using var connection = _dbConnectionFactory.CreateConnection();
        return await connection.QueryAsync<ElectionResult>(
            "assoc.sp_ElectionResults_Get",
            new { ElectionId = electionId },
            commandType: CommandType.StoredProcedure);
    }

    public async Task<bool> HasUserVotedAsync(int electionId, int memberId)
    {
        using var connection = _dbConnectionFactory.CreateConnection();
        return await connection.ExecuteScalarAsync<int>(
            "assoc.sp_Votes_Check",
            new { ElectionId = electionId, MemberId = memberId },
            commandType: CommandType.StoredProcedure) > 0;
    }
}
