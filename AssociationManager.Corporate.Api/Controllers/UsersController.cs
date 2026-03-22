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
[Authorize(Policy = "RequireCorporate")]
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

        if (_tenantContext.TenantId == 0)
        {
            var allUsers = await _userRepository.GetAllAsync();
            return Ok(ApiResponse<IEnumerable<User>>.SuccessResponse(allUsers));
        }

        var tenantUsers = await _userRepository.GetByTenantIdAsync(_tenantContext.TenantId);
        return Ok(ApiResponse<IEnumerable<User>>.SuccessResponse(tenantUsers));
    }

    [HttpPut("{userId}/role")]
    [Authorize(Policy = "RequireUserManagement")]
    public async Task<IActionResult> UpdateRole(int userId, [FromBody] UpdateRoleRequest request)
    {
        if (string.IsNullOrEmpty(request.Role))
            return BadRequest(ApiResponse.FailureResponse("Role cannot be empty."));

        int targetTenantId = _tenantContext.TenantId == 0 ? 1 : _tenantContext.TenantId;

        // Corporate API always updates the global user role directly
        var user = await _userRepository.GetByIdAsync(userId);
        if (user != null)
        {
            user.Role = request.Role;
            await _userRepository.UpdateAsync(user);
        }
        else
        {
            return NotFound(ApiResponse.FailureResponse("User not found in global directory."));
        }

        // Update the association role
        var success = await _userRepository.AddUserToTenantAsync(userId, targetTenantId, request.Role);
        if (success)
            return Ok(ApiResponse.SuccessResponse("Role updated successfully."));

        return BadRequest(ApiResponse.FailureResponse("Failed to update role."));
    }

    [HttpDelete("{userId}")]
    [Authorize(Policy = "RequireUserManagement")]
    public async Task<IActionResult> RemoveFromTenant(int userId)
    {
        if (userId == _tenantContext.UserId)
            return BadRequest(ApiResponse.FailureResponse("You cannot remove yourself from the association."));

        // Corporate API explicitly handles deletion of global corporate personnel
        var globalSuccess = await _userRepository.DeleteUserGlobalAsync(userId);
        if (globalSuccess) return Ok(ApiResponse.SuccessResponse("User permanently removed from the platform."));
        return NotFound(ApiResponse.FailureResponse("User not found."));
    }

    [HttpPost("add-by-email")]
    [Authorize(Policy = "RequireUserManagement")]
    public async Task<IActionResult> AddMemberByEmail([FromBody] AddMemberRequest request)
    {
        if (string.IsNullOrEmpty(request.Email))
            return BadRequest(ApiResponse.FailureResponse("Email is required."));

        var tenantId = _tenantContext.TenantId == 0 ? 1 : _tenantContext.TenantId;

        var user = await _userRepository.GetByEmailAsync(request.Email);
        if (user == null)
        {
            user = new User 
            {
                Email = request.Email,
                Name = "Pending Verification",
                GoogleId = string.Empty,
                Role = request.Role ?? AppRole.Resident,
                TenantId = tenantId,
                IsActive = true
            };
            var newUserId = await _userRepository.CreateAsync(user);
            user.UserId = newUserId;
        }

        // Check if already in tenant
        var currentRole = await _userRepository.GetRoleInTenantAsync(user.UserId, tenantId);
        if (currentRole != null)
            return BadRequest(ApiResponse.FailureResponse("User is already a member of this workspace."));

        var success = await _userRepository.AddUserToTenantAsync(user.UserId, tenantId, request.Role ?? AppRole.Resident);
        if (success)
            return Ok(ApiResponse.SuccessResponse($"Added {request.Email} to system."));

        return BadRequest(ApiResponse.FailureResponse("Failed to add user to system."));
    }
}
