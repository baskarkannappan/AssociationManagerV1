using AssociationManager.Data.Interfaces;
using AssociationManager.Services.Interfaces;
using AssociationManager.Shared.Models;
using System.Collections.Generic;
using System.Threading.Tasks;

namespace AssociationManager.Services.Implementations;

public class GovernanceService : IGovernanceService
{
    private readonly IGovernanceRepository _governanceRepository;

    public GovernanceService(IGovernanceRepository governanceRepository)
    {
        _governanceRepository = governanceRepository;
    }

    public Task<AssociationProfile?> GetProfileAsync(int associationId) => _governanceRepository.GetProfileAsync(associationId);
    public Task<bool> UpdateProfileAsync(AssociationProfile profile) => _governanceRepository.UpdateProfileAsync(profile);

    public Task<IEnumerable<CommitteeRole>> GetCommitteeRolesAsync() => _governanceRepository.GetCommitteeRolesAsync();
    public Task<IEnumerable<CommitteeMember>> GetCommitteeMembersAsync(int associationId, bool activeOnly = true) => _governanceRepository.GetCommitteeMembersAsync(associationId, activeOnly);
    public Task<int> AddCommitteeMemberAsync(CommitteeMember member) => _governanceRepository.AddCommitteeMemberAsync(member);
    public Task<bool> UpdateCommitteeMemberAsync(CommitteeMember member) => _governanceRepository.UpdateCommitteeMemberAsync(member);

    public Task<IEnumerable<ByeLaw>> GetByeLawsAsync(int associationId, bool activeOnly = true) => _governanceRepository.GetByeLawsAsync(associationId, activeOnly);
    public Task<int> CreateByeLawAsync(ByeLaw byeLaw) => _governanceRepository.CreateByeLawAsync(byeLaw);
    public Task<bool> UpdateByeLawAsync(ByeLaw byeLaw) => _governanceRepository.UpdateByeLawAsync(byeLaw);
    public Task<bool> DeleteByeLawAsync(int id) => _governanceRepository.DeleteByeLawAsync(id);
    public Task<ByeLaw?> GetByeLawByIdAsync(int id) => _governanceRepository.GetByeLawByIdAsync(id);

    public async Task<IEnumerable<Meeting>> GetMeetingsAsync(int associationId)
    {
        var meetings = await _governanceRepository.GetMeetingsAsync(associationId);
        foreach (var meeting in meetings)
        {
            meeting.Minutes = (List<MeetingMinutes>)await _governanceRepository.GetMeetingMinutesAsync(meeting.MeetingId);
        }
        return meetings;
    }

    public Task<int> CreateMeetingAsync(Meeting meeting) => _governanceRepository.CreateMeetingAsync(meeting);
    public Task<int> AddMeetingMinutesAsync(MeetingMinutes minutes) => _governanceRepository.AddMeetingMinutesAsync(minutes);

    public async Task<IEnumerable<Election>> GetElectionsAsync(int associationId, bool activeOnly = true)
    {
        var elections = await _governanceRepository.GetElectionsAsync(associationId, activeOnly);
        foreach (var election in elections)
        {
            // Optionally load candidates
        }
        return elections;
    }

    public Task<int> CreateElectionAsync(Election election) => _governanceRepository.CreateElectionAsync(election);
    public Task<int> AddCandidateAsync(Candidate candidate) => _governanceRepository.AddCandidateAsync(candidate);
    public Task<bool> CastVoteAsync(Vote vote) => _governanceRepository.CastVoteAsync(vote);
    public Task<IEnumerable<ElectionResult>> GetElectionResultsAsync(int electionId) => _governanceRepository.GetElectionResultsAsync(electionId);
    public Task<bool> HasUserVotedAsync(int electionId, int memberId) => _governanceRepository.HasUserVotedAsync(electionId, memberId);
}
