using AssociationManager.Services.Interfaces;
using AssociationManager.Shared.Models;
using AssociationManager.Shared.Interfaces;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using System.Collections.Generic;
using System.Threading.Tasks;

namespace AssociationManager.Api.Controllers;

[Authorize]
[ApiController]
[Route("api/[controller]")]
public class GovernanceController : ControllerBase
{
    private readonly IGovernanceService _governanceService;
    private readonly ITenantContext _tenantContext;

    public GovernanceController(IGovernanceService governanceService, ITenantContext tenantContext)
    {
        _governanceService = governanceService;
        _tenantContext = tenantContext;
    }

    [HttpGet("profile")]
    public async Task<IActionResult> GetProfile()
    {
        var profile = await _governanceService.GetProfileAsync(_tenantContext.AssociationId);
        return Ok(ApiResponse<AssociationProfile>.SuccessResponse(profile ?? new AssociationProfile { AssociationId = _tenantContext.AssociationId }));
    }

    [HttpPost("profile")]
    [Authorize(Policy = "RequireAssociationAdmin")]
    public async Task<IActionResult> UpdateProfile([FromBody] AssociationProfile profile)
    {
        profile.AssociationId = _tenantContext.AssociationId;
        var success = await _governanceService.UpdateProfileAsync(profile);
        return success ? Ok(ApiResponse.SuccessResponse("Profile updated.")) : BadRequest(ApiResponse.FailureResponse("Failed to update profile."));
    }

    [HttpGet("committee/roles")]
    public async Task<IActionResult> GetCommitteeRoles()
    {
        var roles = await _governanceService.GetCommitteeRolesAsync();
        return Ok(ApiResponse<IEnumerable<CommitteeRole>>.SuccessResponse(roles));
    }

    [HttpGet("committee/members")]
    public async Task<IActionResult> GetCommitteeMembers([FromQuery] bool activeOnly = true)
    {
        var members = await _governanceService.GetCommitteeMembersAsync(_tenantContext.AssociationId, activeOnly);
        return Ok(ApiResponse<IEnumerable<CommitteeMember>>.SuccessResponse(members));
    }

    [HttpPost("committee/members")]
    [Authorize(Policy = "RequireAssociationAdmin")]
    public async Task<IActionResult> AddCommitteeMember([FromBody] CommitteeMember member)
    {
        member.AssociationId = _tenantContext.AssociationId;
        var id = await _governanceService.AddCommitteeMemberAsync(member);
        return Ok(ApiResponse<int>.SuccessResponse(id, "Member assigned to committee."));
    }

    [HttpPut("committee/members/{id}")]
    [Authorize(Policy = "RequireAssociationAdmin")]
    public async Task<IActionResult> UpdateCommitteeMember(int id, [FromBody] CommitteeMember member)
    {
        member.CommitteeMemberId = id;
        member.AssociationId = _tenantContext.AssociationId;
        var success = await _governanceService.UpdateCommitteeMemberAsync(member);
        return success ? Ok(ApiResponse.SuccessResponse("Committee member updated.")) : BadRequest(ApiResponse.FailureResponse("Failed to update committee member."));
    }

    [HttpGet("byelaws")]
    public async Task<IActionResult> GetByeLaws([FromQuery] bool activeOnly = true)
    {
        var laws = await _governanceService.GetByeLawsAsync(_tenantContext.AssociationId, activeOnly);
        return Ok(ApiResponse<IEnumerable<ByeLaw>>.SuccessResponse(laws));
    }

    [HttpPost("byelaws")]
    [Authorize(Policy = "RequireAssociationAdmin")]
    public async Task<IActionResult> CreateByeLaw([FromBody] ByeLaw byeLaw)
    {
        byeLaw.AssociationId = _tenantContext.AssociationId;
        var id = await _governanceService.CreateByeLawAsync(byeLaw);
        return Ok(ApiResponse<int>.SuccessResponse(id, "Bye-law created."));
    }

    [HttpPut("byelaws/{id}")]
    [Authorize(Policy = "RequireAssociationAdmin")]
    public async Task<IActionResult> UpdateByeLaw(int id, [FromBody] ByeLaw byeLaw)
    {
        byeLaw.ByeLawId = id;
        byeLaw.AssociationId = _tenantContext.AssociationId;
        var success = await _governanceService.UpdateByeLawAsync(byeLaw);
        return success ? Ok(ApiResponse.SuccessResponse("Bye-law updated.")) : BadRequest(ApiResponse.FailureResponse("Failed to update bye-law."));
    }

    [HttpDelete("byelaws/{id}")]
    [Authorize(Policy = "RequireAssociationAdmin")]
    public async Task<IActionResult> DeleteByeLaw(int id)
    {
        // For now, we don't have a direct Delete in Service, but we can implement it or just deactivate.
        // The user asked for "Add, Update, Delete".
        // I'll add Delete to IGovernanceService/Repository too.
        var success = await _governanceService.DeleteByeLawAsync(id);
        return success ? Ok(ApiResponse.SuccessResponse("Bye-law deleted.")) : BadRequest(ApiResponse.FailureResponse("Failed to delete bye-law."));
    }

    [HttpGet("byelaws/{id}/download")]
    public async Task<IActionResult> DownloadByeLaw(int id)
    {
        var byeLaw = await _governanceService.GetByeLawByIdAsync(id);
        if (byeLaw?.DocumentContent == null) return NotFound(ApiResponse.FailureResponse("Document not found."));
        
        return File(byeLaw.DocumentContent, byeLaw.ContentType ?? "application/octet-stream", byeLaw.FileName ?? $"ByeLaw_{id}.pdf");
    }

    [HttpGet("meetings")]
    public async Task<IActionResult> GetMeetings()
    {
        var meetings = await _governanceService.GetMeetingsAsync(_tenantContext.AssociationId);
        return Ok(ApiResponse<IEnumerable<Meeting>>.SuccessResponse(meetings));
    }

    [HttpPost("meetings")]
    [Authorize(Policy = "RequireAssociationAdmin")]
    public async Task<IActionResult> CreateMeeting([FromBody] Meeting meeting)
    {
        meeting.AssociationId = _tenantContext.AssociationId;
        meeting.CreatedBy = _tenantContext.UserId;
        var id = await _governanceService.CreateMeetingAsync(meeting);
        return Ok(ApiResponse<int>.SuccessResponse(id, "Meeting scheduled."));
    }

    [HttpPost("meetings/minutes")]
    [Authorize(Policy = "RequireAssociationAdmin")]
    public async Task<IActionResult> AddMinutes([FromBody] MeetingMinutes minutes)
    {
        var id = await _governanceService.AddMeetingMinutesAsync(minutes);
        return Ok(ApiResponse<int>.SuccessResponse(id, "Minutes added."));
    }

    [HttpGet("elections")]
    public async Task<IActionResult> GetElections([FromQuery] bool activeOnly = true)
    {
        var elections = await _governanceService.GetElectionsAsync(_tenantContext.AssociationId, activeOnly);
        return Ok(ApiResponse<IEnumerable<Election>>.SuccessResponse(elections));
    }

    [HttpPost("elections")]
    [Authorize(Policy = "RequireAssociationAdmin")]
    public async Task<IActionResult> CreateElection([FromBody] Election election)
    {
        election.AssociationId = _tenantContext.AssociationId;
        var id = await _governanceService.CreateElectionAsync(election);
        return Ok(ApiResponse<int>.SuccessResponse(id, "Election created."));
    }

    [HttpPost("elections/vote")]
    public async Task<IActionResult> CastVote([FromBody] Vote vote)
    {
        vote.MemberId = _tenantContext.UserId;
        var success = await _governanceService.CastVoteAsync(vote);
        return success ? Ok(ApiResponse.SuccessResponse("Vote cast.")) : BadRequest(ApiResponse.FailureResponse("Failed to cast vote (already voted or election complete)."));
    }

    [HttpGet("elections/{id}/results")]
    public async Task<IActionResult> GetResults(int id)
    {
        var results = await _governanceService.GetElectionResultsAsync(id);
        return Ok(ApiResponse<IEnumerable<ElectionResult>>.SuccessResponse(results));
    }
}
