using AssociationManager.Data.Interfaces;
using AssociationManager.Shared.Models;
using AssociationManager.Shared.Interfaces;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using System.Collections.Generic;
using System.Threading.Tasks;

namespace AssociationManager.Corporate.Api.Controllers;

[Authorize(Policy = "RequirePlatformAdmin")]
[ApiController]
[Route("api/[controller]")]
public class ContentManagementController : ControllerBase
{
    private readonly IContentRepository _contentRepository;
    private readonly ITenantContext _tenantContext;

    public ContentManagementController(IContentRepository contentRepository, ITenantContext tenantContext)
    {
        _contentRepository = contentRepository;
        _tenantContext = tenantContext;
    }

    [HttpPost("upsert")]
    public async Task<IActionResult> UpsertContent([FromBody] StaticContent content)
    {
        content.UpdatedBy = _tenantContext.UserId;
        var success = await _contentRepository.UpsertStaticContentAsync(content);
        return Ok(ApiResponse<bool>.SuccessResponse(success, "Content updated successfully."));
    }

    [HttpGet("queries")]
    public async Task<IActionResult> GetAllQueries()
    {
        var queries = await _contentRepository.GetAllSupportQueriesAsync();
        return Ok(ApiResponse<IEnumerable<SupportQuery>>.SuccessResponse(queries));
    }
}
