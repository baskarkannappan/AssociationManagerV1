using AssociationManager.Shared.Models;
using System.Collections.Generic;
using System.Threading.Tasks;

namespace AssociationManager.Data.Interfaces;

public interface IGovernanceRepository
{
    // Profile
    Task<AssociationProfile?> GetProfileAsync(int associationId);
    Task<bool> UpdateProfileAsync(AssociationProfile profile);

    // Committee
    Task<IEnumerable<CommitteeRole>> GetCommitteeRolesAsync();
    Task<IEnumerable<CommitteeMember>> GetCommitteeMembersAsync(int associationId, bool activeOnly = true);
    Task<int> AddCommitteeMemberAsync(CommitteeMember member);
    Task<bool> UpdateCommitteeMemberAsync(CommitteeMember member);

    // Bye-laws
    Task<IEnumerable<ByeLaw>> GetByeLawsAsync(int associationId, bool activeOnly = true);
    Task<int> CreateByeLawAsync(ByeLaw byeLaw);
    Task<bool> UpdateByeLawAsync(ByeLaw byeLaw);
    Task<bool> DeleteByeLawAsync(int id);
    Task<ByeLaw?> GetByeLawByIdAsync(int id);

    // Meetings
    Task<IEnumerable<Meeting>> GetMeetingsAsync(int associationId);
    Task<int> CreateMeetingAsync(Meeting meeting);
    Task<int> AddMeetingMinutesAsync(MeetingMinutes minutes);
    Task<IEnumerable<MeetingMinutes>> GetMeetingMinutesAsync(int meetingId);

    // Elections
    Task<IEnumerable<Election>> GetElectionsAsync(int associationId, bool activeOnly = true);
    Task<int> CreateElectionAsync(Election election);
    Task<int> AddCandidateAsync(Candidate candidate);
    Task<bool> CastVoteAsync(Vote vote);
    Task<IEnumerable<ElectionResult>> GetElectionResultsAsync(int electionId);
    Task<bool> HasUserVotedAsync(int electionId, int memberId);
}
