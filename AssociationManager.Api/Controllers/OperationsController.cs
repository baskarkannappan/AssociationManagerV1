using AssociationManager.Api.Authorization;
using AssociationManager.Services.Interfaces;
using AssociationManager.Shared.Models;
using AssociationManager.Shared.Enums;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using System.Collections.Generic;
using System.Threading.Tasks;

namespace AssociationManager.Api.Controllers;

[Authorize]
[RequireRole(AppRole.AssetManager, AppRole.AssociationAdmin)]
[ApiController]
[Route("api/[controller]")]
public class OperationsController : ControllerBase
{
    private readonly IOperationsService _operationsService;
    private readonly IAuditService _auditService;

    public OperationsController(IOperationsService operationsService, IAuditService auditService)
    {
        _operationsService = operationsService;
        _auditService = auditService;
    }

    [HttpGet("workorders")]
    public async Task<IActionResult> GetWorkOrders()
    {
        var workOrders = await _operationsService.GetAllWorkOrdersAsync();
        return Ok(workOrders);
    }

    [HttpGet("workorders/{id}")]
    public async Task<IActionResult> GetWorkOrder(int id)
    {
        var workOrder = await _operationsService.GetWorkOrderByIdAsync(id);
        if (workOrder == null) return NotFound();
        return Ok(workOrder);
    }

    [HttpPost("workorders")]
    public async Task<IActionResult> CreateWorkOrder([FromBody] WorkOrder workOrder)
    {
        var id = await _operationsService.CreateWorkOrderAsync(workOrder);
        await _auditService.LogAsync("Create Work Order", "WorkOrder", id);
        return CreatedAtAction(nameof(GetWorkOrder), new { id }, workOrder);
    }

    [HttpPut("workorders/{id}")]
    public async Task<IActionResult> UpdateWorkOrder(int id, [FromBody] WorkOrder workOrder)
    {
        workOrder.WorkOrderId = id;
        var success = await _operationsService.UpdateWorkOrderAsync(workOrder);
        if (!success) return NotFound();
        await _auditService.LogAsync("Update Work Order", "WorkOrder", id);
        return NoContent();
    }

    [HttpPut("workorders/{id}/status")]
    public async Task<IActionResult> UpdateStatus(int id, [FromBody] string status)
    {
        var success = await _operationsService.UpdateWorkOrderStatusAsync(id, status);
        if (!success) return NotFound();
        await _auditService.LogAsync("Update Work Order Status", "WorkOrder", id);
        return NoContent();
    }

    [HttpDelete("workorders/{id}")]
    public async Task<IActionResult> Delete(int id)
    {
        var success = await _operationsService.DeleteWorkOrderAsync(id);
        if (!success) return NotFound();
        await _auditService.LogAsync("Delete Work Order", "WorkOrder", id);
        return NoContent();
    }
}
