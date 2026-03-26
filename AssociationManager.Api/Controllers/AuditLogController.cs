using AssociationManager.Services.Interfaces;
using AssociationManager.Shared.Models;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using System.Collections.Generic;
using System.Threading.Tasks;

namespace AssociationManager.Api.Controllers;

[Authorize]
[ApiController]
[Route("api/[controller]")]
public class AuditLogController : ControllerBase
{
    private readonly IAuditService _auditService;

    public AuditLogController(IAuditService auditService)
    {
        _auditService = auditService;
    }

    [HttpGet("asset/{assetId}")]
    [Authorize(Roles = "PlatformAdmin,SystemAdmin,AssociationAdmin,FinanceManager")]
    public async Task<IActionResult> GetAssetLogs(int assetId)
    {
        var logs = await _auditService.GetAssetLogsAsync(assetId);
        return Ok(ApiResponse<IEnumerable<AuditLog>>.SuccessResponse(logs));
    }
}
