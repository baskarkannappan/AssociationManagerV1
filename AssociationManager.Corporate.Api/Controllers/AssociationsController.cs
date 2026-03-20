using AssociationManager.Services.Interfaces;
using AssociationManager.Shared.Models;
using AssociationManager.Shared.Interfaces;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using System;
using System.Collections.Generic;
using System.Threading.Tasks;

namespace AssociationManager.Corporate.Api.Controllers;

[Authorize]
[ApiController]
[Route("api/[controller]")]
public class AssociationsController : ControllerBase
{
    private readonly IAssociationService _associationService;
    private readonly IAuditService _auditService;
    private readonly ITenantContext _tenantContext;

    public AssociationsController(IAssociationService associationService, IAuditService auditService, ITenantContext tenantContext)
    {
        _associationService = associationService;
        _auditService = auditService;
        _tenantContext = tenantContext;
    }

    [HttpGet("my-tenants")]
    public async Task<IActionResult> GetMyTenants()
    {
        var associations = await _associationService.GetByUserIdAsync(_tenantContext.UserId);
        return Ok(ApiResponse<IEnumerable<Association>>.SuccessResponse(associations));
    }

    [HttpGet]
    [Authorize(Policy = "RequireAssociationAdmin")]
    public async Task<IActionResult> GetAll()
    {
        try 
        {
            var associations = await _associationService.GetAllByTenantAsync();
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
        return Ok(ApiResponse<Association>.SuccessResponse(association));
    }

    [HttpPost]
    [Authorize(Policy = "RequireAssociationAdmin")]
    public async Task<IActionResult> Create([FromBody] Association association)
    {
        var id = await _associationService.CreateAsync(association);
        await _auditService.LogAsync("Create Association", "Association", id);
        return CreatedAtAction(nameof(GetById), new { id }, ApiResponse<int>.SuccessResponse(id, "Association created successfully."));
    }

    [HttpPut("{id}")]
    [Authorize(Policy = "RequireAssociationAdmin")]
    public async Task<IActionResult> Update(int id, [FromBody] Association association)
    {
        association.AssociationId = id;
        var success = await _associationService.UpdateAsync(association);
        if (!success) return NotFound(ApiResponse.FailureResponse("Association not found for update."));
        await _auditService.LogAsync("Update Association", "Association", id);
        return Ok(ApiResponse.SuccessResponse("Association updated successfully."));
    }

    [HttpDelete("{id}")]
    [Authorize(Policy = "RequireAssociationAdmin")]
    public async Task<IActionResult> Delete(int id)
    {
        var success = await _associationService.DeleteAsync(id);
        if (!success) return NotFound(ApiResponse.FailureResponse("Association not found for deletion."));
        await _auditService.LogAsync("Delete Association", "Association", id);
        return Ok(ApiResponse.SuccessResponse("Association deleted successfully."));
    }
}
