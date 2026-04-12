using AssociationManager.Auth.Models;
using AssociationManager.Data.Interfaces;
using AssociationManager.Shared.Enums;
using AssociationManager.Shared.Interfaces;
using AssociationManager.Shared.Models;
using AssociationManager.Services.Interfaces;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using System;
using System.Collections.Generic;
using System.Threading.Tasks;

namespace AssociationManager.Api.Controllers;

[ApiController]
[Route("api/[controller]")]
[Authorize(Policy = "RequireUserManager")]
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
    public async Task<IActionResult> GetUsers(
        [FromQuery] int? associationId = null,
        [FromQuery] string? searchTerm = null,
        [FromQuery] string? role = null,
        [FromQuery] int pageNumber = 1,
        [FromQuery] int pageSize = 10,
        [FromQuery] string sortColumn = "Name",
        [FromQuery] string sortDirection = "ASC")
    {
        var criteria = new UserSearchCriteria
        {
            AssociationId = associationId ?? _tenantContext.AssociationId,
            SearchTerm = searchTerm,
            Role = role,
            PageNumber = pageNumber,
            PageSize = pageSize,
            SortColumn = sortColumn,
            SortDirection = sortDirection
        };

        var result = await _userRepository.GetPagedAsync(criteria);
        return Ok(ApiResponse<PagedResult<User>>.SuccessResponse(result));
    }


    [HttpPut("{userId}/role")]
    [Authorize(Policy = "RequireAssociationAdmin")]
    public async Task<IActionResult> UpdateRole(int userId, [FromBody] UpdateRoleRequest request)
    {
        if (string.IsNullOrEmpty(request.Role))
            return BadRequest(ApiResponse.FailureResponse("Role cannot be empty."));

        // Verify user is in tenant
        var currentRole = await _userRepository.GetRoleInTenantAsync(userId, _tenantContext.AssociationId);
        if (currentRole == null)
            return NotFound(ApiResponse.FailureResponse("User not found in this association."));

        // Update the association role
        var success = await _userRepository.AddUserToTenantAsync(userId, _tenantContext.AssociationId, request.Role);
        if (success)
            return Ok(ApiResponse.SuccessResponse("Role updated successfully."));

        return BadRequest(ApiResponse.FailureResponse("Failed to update role."));
    }

    [HttpDelete("{userId}")]
    [Authorize(Policy = "RequireAssociationAdmin")]
    public async Task<IActionResult> RemoveFromTenant(int userId)
    {
        if (userId == _tenantContext.UserId)
            return BadRequest(ApiResponse.FailureResponse("You cannot remove yourself from the association."));

        var success = await _userRepository.RemoveUserFromTenantAsync(userId, _tenantContext.AssociationId);
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
        {
            // Provision new user in assoc.Users
            user = new User
            {
                Email = request.Email,
                Name = request.Email.Split('@')[0], // Default name
                CreatedDate = DateTime.UtcNow,
                IsActive = true,
                Role = "User" // Base role in user table
            };
            user.UserId = await _userRepository.CreateAsync(user);
        }

        // Check if already in association mapping
        var currentRole = await _userRepository.GetRoleInTenantAsync(user.UserId, _tenantContext.AssociationId);
        if (currentRole != null)
            return BadRequest(ApiResponse.FailureResponse("User is already a member of this association."));

        var success = await _userRepository.AddUserToTenantAsync(user.UserId, _tenantContext.AssociationId, request.Role ?? AppRole.Resident);
        if (success)
            return Ok(ApiResponse.SuccessResponse($"Added {user.Name} to association."));

        return BadRequest(ApiResponse.FailureResponse("Failed to add user to association."));
    }
}
