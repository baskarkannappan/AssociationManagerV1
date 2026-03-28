using AssociationManager.Api.Authorization;
using AssociationManager.Services.Interfaces;
using AssociationManager.Shared.Interfaces;
using AssociationManager.Shared.Models;
using AssociationManager.Shared.Enums;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using System;
using System.Collections.Generic;
using System.Threading.Tasks;

namespace AssociationManager.Api.Controllers;

[Authorize(Policy = "RequireResident")]
[ApiController]
[Route("api/[controller]")]
public class OperationsController : ControllerBase
{
    private readonly IOperationsService _operationsService;
    private readonly IAuditService _auditService;
    private readonly IRuleEngineService _ruleEngine;
    private readonly ITenantContext _tenantContext;
    private readonly IPeopleService _peopleService;

    public OperationsController(
        IOperationsService operationsService, 
        IAuditService auditService,
        IRuleEngineService ruleEngine,
        ITenantContext tenantContext,
        IPeopleService peopleService)
    {
        _operationsService = operationsService;
        _auditService = auditService;
        _ruleEngine = ruleEngine;
        _tenantContext = tenantContext;
        _peopleService = peopleService;
    }

    [HttpGet("workorders")]
    public async Task<IActionResult> GetWorkOrders([FromQuery] int? assetId = null)
    {
        var roles = User.Claims.Where(c => c.Type == "role" || c.Type == System.Security.Claims.ClaimTypes.Role)
                              .Select(c => c.Value);

        var securityContext = new SecurityContext
        {
            UserRole = string.Join(",", roles),
            UserLevel = AppRole.GetMaxLevel(User.Claims),
            AssociationId = _tenantContext.AssociationId,
            Action = "View",
            Resource = "WorkOrders"
        };

        bool isStaff = await _ruleEngine.EvaluateRuleAsync("IsStaff", securityContext);
        
        if (!isStaff)
        {
            var userIdStr = User.FindFirst("UserId")?.Value;
            if (int.TryParse(userIdStr, out int userId))
            {
                var occupancies = await _peopleService.GetOccupancyByUserIdAsync(userId);
                var allowedAssetIds = occupancies.Select(o => o.AssetId).ToList();
                
                if (assetId.HasValue)
                {
                    securityContext.AssetId = assetId.Value;
                    securityContext.IsPrimaryResident = allowedAssetIds.Contains(assetId.Value);
                    if (!await _ruleEngine.EvaluateRuleAsync("CanViewAsset", securityContext))
                    {
                        return Forbid();
                    }
                }
                else
                {
                    if (!allowedAssetIds.Any()) return Ok(ApiResponse<IEnumerable<WorkOrder>>.SuccessResponse(new List<WorkOrder>()));
                    assetId = allowedAssetIds.First();
                }
            }
        }

        IEnumerable<WorkOrder> workOrders;
        if (assetId.HasValue)
        {
            workOrders = await _operationsService.GetWorkOrdersByAssetIdAsync(assetId.Value);
        }
        else
        {
            workOrders = await _operationsService.GetAllWorkOrdersAsync();
        }
        return Ok(ApiResponse<IEnumerable<WorkOrder>>.SuccessResponse(workOrders));
    }

    [HttpGet("workorders/{id}")]
    public async Task<IActionResult> GetWorkOrder(int id)
    {
        var workOrder = await _operationsService.GetWorkOrderByIdAsync(id);
        if (workOrder == null) return NotFound(ApiResponse.FailureResponse("Work order not found."));
        
        // Authorization check for residents
        var roles = User.Claims.Where(c => c.Type == "role" || c.Type == System.Security.Claims.ClaimTypes.Role)
                              .Select(c => c.Value);

        var securityContext = new SecurityContext
        {
            UserRole = string.Join(",", roles),
            UserLevel = AppRole.GetMaxLevel(User.Claims),
            AssociationId = _tenantContext.AssociationId,
            AssetId = workOrder.AssetId,
            Action = "View",
            Resource = "WorkOrders"
        };

        var userIdStr = User.FindFirst("UserId")?.Value;
        if (int.TryParse(userIdStr, out int userId))
        {
            securityContext.IsPrimaryResident = await _peopleService.IsPrimaryResidentForAssetAsync(userId, workOrder.AssetId ?? 0);
        }

        if (!await _ruleEngine.EvaluateRuleAsync("CanViewAsset", securityContext))
        {
            return Forbid();
        }

        return Ok(ApiResponse<WorkOrder>.SuccessResponse(workOrder));
    }

    [HttpPost("workorders")]
    [Authorize(Policy = "RequireAssetManager")]
    public async Task<IActionResult> CreateWorkOrder([FromBody] WorkOrder workOrder)
    {
        var id = await _operationsService.CreateWorkOrderAsync(workOrder);
        await _auditService.LogAsync("Create Work Order", "WorkOrder", id);
        return CreatedAtAction(nameof(GetWorkOrder), new { id }, ApiResponse<int>.SuccessResponse(id, "Work order created."));
    }

    [HttpPut("workorders/{id}")]
    [Authorize(Policy = "RequireAssetManager")]
    public async Task<IActionResult> UpdateWorkOrder(int id, [FromBody] WorkOrder workOrder)
    {
        workOrder.WorkOrderId = id;
        var success = await _operationsService.UpdateWorkOrderAsync(workOrder);
        if (!success) return NotFound(ApiResponse.FailureResponse("Work order not found for update."));
        await _auditService.LogAsync("Update Work Order", "WorkOrder", id);
        return Ok(ApiResponse.SuccessResponse("Work order updated."));
    }

    [HttpPut("workorders/{id}/status")]
    [Authorize(Policy = "RequireAssetManager")]
    public async Task<IActionResult> UpdateStatus(int id, [FromBody] string status)
    {
        var success = await _operationsService.UpdateWorkOrderStatusAsync(id, status);
        if (!success) return NotFound(ApiResponse.FailureResponse("Work order not found for status update."));
        await _auditService.LogAsync("Update Work Order Status", "WorkOrder", id);
        return Ok(ApiResponse.SuccessResponse("Work order status updated."));
    }

    [HttpDelete("workorders/{id}")]
    [Authorize(Policy = "RequireAssetManager")]
    public async Task<IActionResult> Delete(int id)
    {
        var success = await _operationsService.DeleteWorkOrderAsync(id);
        if (!success) return NotFound(ApiResponse.FailureResponse("Work order not found for deletion."));
        await _auditService.LogAsync("Delete Work Order", "WorkOrder", id);
        return Ok(ApiResponse.SuccessResponse("Work order deleted."));
    }
}
