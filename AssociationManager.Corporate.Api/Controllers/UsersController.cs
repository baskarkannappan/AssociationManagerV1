using AssociationManager.Auth.Models;
using AssociationManager.Data.Interfaces;
using AssociationManager.Shared.Enums;
using AssociationManager.Shared.Interfaces;
using AssociationManager.Shared.Models;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using System;
using System.Collections.Generic;
using System.Threading.Tasks;

namespace AssociationManager.Corporate.Api.Controllers;

[ApiController]
[Route("api/[controller]")]
[Authorize(Policy = "RequireAssociationAdmin")]
public class UsersController : ControllerBase
{
    private readonly IUserRepository _userRepository;
    private readonly ITenantContext _tenantContext;

    public UsersController(IUserRepository userRepository, ITenantContext tenantContext)
    {
        _userRepository = userRepository;
        _tenantContext = tenantContext;
    }

    [HttpGet]
    public async Task<IActionResult> GetUsers([FromQuery] int? associationId = null)
    {
        if (associationId.HasValue)
        {
            var users = await _userRepository.GetByAssociationIdAsync(associationId.Value);
            return Ok(ApiResponse<IEnumerable<User>>.SuccessResponse(users));
        }

        var tenantUsers = await _userRepository.GetByTenantIdAsync(_tenantContext.TenantId);
        return Ok(ApiResponse<IEnumerable<User>>.SuccessResponse(tenantUsers));
    }

    [HttpPut("{userId}/role")]
    public async Task<IActionResult> UpdateRole(int userId, [FromBody] UpdateRoleRequest request)
    {
        if (string.IsNullOrEmpty(request.Role))
            return BadRequest(ApiResponse.FailureResponse("Role cannot be empty."));

        // Verify user is in tenant
        var currentRole = await _userRepository.GetRoleInTenantAsync(userId, _tenantContext.TenantId);
        if (currentRole == null)
            return NotFound(ApiResponse.FailureResponse("User not found in this association."));

        // Update the association role
        var success = await _userRepository.AddUserToTenantAsync(userId, _tenantContext.TenantId, request.Role);
        if (success)
            return Ok(ApiResponse.SuccessResponse("Role updated successfully."));

        return BadRequest(ApiResponse.FailureResponse("Failed to update role."));
    }

    [HttpDelete("{userId}")]
    public async Task<IActionResult> RemoveFromTenant(int userId)
    {
        if (userId == _tenantContext.UserId)
            return BadRequest(ApiResponse.FailureResponse("You cannot remove yourself from the association."));

        var success = await _userRepository.RemoveUserFromTenantAsync(userId, _tenantContext.TenantId);
        if (success)
            return Ok(ApiResponse.SuccessResponse("User removed from association."));

        return NotFound(ApiResponse.FailureResponse("User association not found."));
    }

    [HttpPost("add-by-email")]
    public async Task<IActionResult> AddMemberByEmail([FromBody] AddMemberRequest request)
    {
        if (string.IsNullOrEmpty(request.Email))
            return BadRequest(ApiResponse.FailureResponse("Email is required."));

        var user = await _userRepository.GetByEmailAsync(request.Email);
        if (user == null)
            return NotFound(ApiResponse.FailureResponse("User with this email does not exist. They must sign in to the application once first."));

        // Check if already in tenant
        var currentRole = await _userRepository.GetRoleInTenantAsync(user.UserId, _tenantContext.TenantId);
        if (currentRole != null)
            return BadRequest(ApiResponse.FailureResponse("User is already a member of this association."));

        var success = await _userRepository.AddUserToTenantAsync(user.UserId, _tenantContext.TenantId, request.Role ?? AppRole.Resident);
        if (success)
            return Ok(ApiResponse.SuccessResponse($"Added {user.Name} to association."));

        return BadRequest(ApiResponse.FailureResponse("Failed to add user to association."));
    }
}
