using AssociationManager.Data.Interfaces;
using AssociationManager.Shared.Models;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using System.Threading.Tasks;

namespace AssociationManager.Api.Controllers;

[ApiController]
[Route("api/[controller]")]
public class PublicContentController : ControllerBase
{
    private readonly IContentRepository _contentRepository;

    public PublicContentController(IContentRepository contentRepository)
    {
        _contentRepository = contentRepository;
    }

    [HttpGet("{key}")]
    [AllowAnonymous]
    public async Task<IActionResult> GetContent(string key)
    {
        var content = await _contentRepository.GetStaticContentAsync(key);
        if (content == null) return NotFound(ApiResponse.FailureResponse("Content not found."));
        return Ok(ApiResponse<StaticContent>.SuccessResponse(content));
    }

    [HttpPost("query")]
    [AllowAnonymous]
    public async Task<IActionResult> PostQuery([FromBody] SupportQuery query)
    {
        if (string.IsNullOrWhiteSpace(query.Name) || string.IsNullOrWhiteSpace(query.Email) || string.IsNullOrWhiteSpace(query.MessageBody))
        {
            return BadRequest(ApiResponse.FailureResponse("Name, Email, and Message are required."));
        }

        var id = await _contentRepository.CreateSupportQueryAsync(query);
        return Ok(ApiResponse<int>.SuccessResponse(id, "Your query has been submitted successfully."));
    }
}
