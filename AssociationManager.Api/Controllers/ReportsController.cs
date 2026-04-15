using AssociationManager.Services.Interfaces;
using AssociationManager.Shared.Models;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using System.Threading.Tasks;

namespace AssociationManager.Api.Controllers;

[ApiController]
[Route("api/[controller]")]
[Authorize(Policy = "RequireFinanceManager")]
public class ReportsController : ControllerBase
{
    private readonly IReportingService _reportingService;

    public ReportsController(IReportingService reportingService)
    {
        _reportingService = reportingService;
    }

    [HttpGet("financial-summary")]
    public async Task<IActionResult> GetFinancialSummary()
    {
        var report = await _reportingService.GetFinancialMetricsV2Async();
        return Ok(ApiResponse<FinancialMetricsReport>.SuccessResponse(report));
    }
}
