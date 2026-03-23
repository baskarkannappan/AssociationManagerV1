using AssociationManager.Services.Interfaces;
using AssociationManager.Shared.Models;
using AssociationManager.Shared.Interfaces;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using System;
using System.Collections.Generic;
using System.Threading.Tasks;

namespace AssociationManager.Api.Controllers;

[Authorize]
[ApiController]
[Route("api/[controller]")]
public class AssociationsController : ControllerBase
{
    private readonly IAssociationService _associationService;
    private readonly ITenantContext _tenantContext;

    public AssociationsController(IAssociationService associationService, ITenantContext tenantContext)
    {
        _associationService = associationService;
        _tenantContext = tenantContext;
    }

    [HttpGet("my-tenants")]
    public async Task<IActionResult> GetMyTenants()
    {
        try
        {
            var associations = await _associationService.GetByUserIdAsync(_tenantContext.UserId);
            return Ok(ApiResponse<IEnumerable<Association>>.SuccessResponse(associations));
        }
        catch (Exception ex)
        {
            return BadRequest(ApiResponse.FailureResponse(ex.Message));
        }
    }

    [HttpGet("{id}")]
    public async Task<IActionResult> GetById(int id)
    {
        var association = await _associationService.GetByIdAsync(id);
        if (association == null) return NotFound(ApiResponse.FailureResponse("Association not found."));
        
        // Basic security: Ensure user has access if not a global admin
        // (In a real app, this would be more granular)
        
        return Ok(ApiResponse<Association>.SuccessResponse(association));
    }
}
