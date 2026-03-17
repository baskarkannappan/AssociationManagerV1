using AssociationManager.Services.Interfaces;
using AssociationManager.Shared.Models;
using AssociationManager.Shared.Interfaces;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using System.Threading.Tasks;

namespace AssociationManager.Api.Controllers;

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
        return Ok(associations);
    }

    [HttpGet]
    public async Task<IActionResult> GetAll()
    {
        var associations = await _associationService.GetAllByTenantAsync();
        return Ok(associations);
    }

    [HttpGet("{id}")]
    public async Task<IActionResult> GetById(int id)
    {
        var association = await _associationService.GetByIdAsync(id);
        if (association == null) return NotFound();
        return Ok(association);
    }

    [HttpPost]
    public async Task<IActionResult> Create([FromBody] Association association)
    {
        var id = await _associationService.CreateAsync(association);
        await _auditService.LogAsync("Create Association", "Association", id);
        return CreatedAtAction(nameof(GetById), new { id }, association);
    }

    [HttpPut("{id}")]
    public async Task<IActionResult> Update(int id, [FromBody] Association association)
    {
        association.AssociationId = id;
        var success = await _associationService.UpdateAsync(association);
        if (!success) return NotFound();
        await _auditService.LogAsync("Update Association", "Association", id);
        return NoContent();
    }

    [HttpDelete("{id}")]
    public async Task<IActionResult> Delete(int id)
    {
        var success = await _associationService.DeleteAsync(id);
        if (!success) return NotFound();
        await _auditService.LogAsync("Delete Association", "Association", id);
        return NoContent();
    }
}
