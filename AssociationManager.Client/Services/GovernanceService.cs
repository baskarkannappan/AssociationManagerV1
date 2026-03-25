using AssociationManager.Shared.Models;
using System.Collections.Generic;
using System.Net.Http.Json;
using System.Threading.Tasks;

namespace AssociationManager.Client.Services;

public class GovernanceService
{
    private readonly ApiService _apiService;

    public GovernanceService(ApiService apiService)
    {
        _apiService = apiService;
    }

    // Profile
    public async Task<AssociationProfile?> GetProfileAsync() 
        => await _apiService.GetAsync<AssociationProfile>("api/governance/profile");

    public async Task<bool> UpdateProfileAsync(AssociationProfile profile) 
        => await _apiService.PostAsync("api/governance/profile", profile);

    // Committee
    public async Task<List<CommitteeRole>> GetCommitteeRolesAsync() 
        => await _apiService.GetAsync<List<CommitteeRole>>("api/governance/committee/roles") ?? new();

    public async Task<List<CommitteeMember>> GetCommitteeMembersAsync(bool activeOnly = true) 
        => await _apiService.GetAsync<List<CommitteeMember>>($"api/governance/committee/members?activeOnly={activeOnly}") ?? new();

    public async Task<bool> AddCommitteeMemberAsync(CommitteeMember member) 
        => await _apiService.PostAsync("api/governance/committee/members", member);

    public async Task<bool> UpdateCommitteeMemberAsync(CommitteeMember member) 
        => await _apiService.PostAsync($"api/governance/committee/members/{member.MemberId}", member);

    // Bye-laws
    public async Task<List<ByeLaw>> GetByeLawsAsync(bool activeOnly = true) 
        => await _apiService.GetAsync<List<ByeLaw>>($"api/governance/byelaws?activeOnly={activeOnly}") ?? new();

    public async Task<bool> CreateByeLawAsync(ByeLaw byeLaw) 
        => await _apiService.PostAsync("api/governance/byelaws", byeLaw);

    public async Task<bool> UpdateByeLawAsync(ByeLaw byeLaw) 
        => await _apiService.PostAsync($"api/governance/byelaws/{byeLaw.ByeLawId}", byeLaw);

    public async Task<bool> DeleteByeLawAsync(int id) 
        => await _apiService.DeleteAsync($"api/governance/byelaws/{id}");

    // Meetings
    public async Task<List<Meeting>> GetMeetingsAsync() 
        => await _apiService.GetAsync<List<Meeting>>("api/governance/meetings") ?? new();

    public async Task<bool> CreateMeetingAsync(Meeting meeting) 
        => await _apiService.PostAsync("api/governance/meetings", meeting);

    public async Task<bool> AddMinutesAsync(MeetingMinutes minutes) 
        => await _apiService.PostAsync("api/governance/meetings/minutes", minutes);

    // Elections
    public async Task<List<Election>> GetElectionsAsync(bool activeOnly = true) 
        => await _apiService.GetAsync<List<Election>>($"api/governance/elections?activeOnly={activeOnly}") ?? new();

    public async Task<bool> CreateElectionAsync(Election election) 
        => await _apiService.PostAsync("api/governance/elections", election);

    public async Task<bool> CastVoteAsync(Vote vote) 
        => await _apiService.PostAsync("api/governance/elections/vote", vote);

    public async Task<bool> HasUserVotedAsync(int electionId, int userId)
        => await _apiService.GetAsync<bool>($"api/governance/elections/{electionId}/hasvoted/{userId}");

    public async Task<List<ElectionResult>> GetResultsAsync(int electionId) 
        => await _apiService.GetAsync<List<ElectionResult>>($"api/governance/elections/{electionId}/results") ?? new();
}
