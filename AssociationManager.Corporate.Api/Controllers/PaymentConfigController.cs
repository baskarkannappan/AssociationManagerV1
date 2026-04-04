using AssociationManager.Data.Interfaces;
using AssociationManager.Shared.Models;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using System.Collections.Generic;
using System.Threading.Tasks;

namespace AssociationManager.Corporate.Api.Controllers;

[Authorize(Policy = "RequirePlatformAdmin")]
[ApiController]
[Route("api/[controller]")]
public class PaymentConfigController : ControllerBase
{
    private readonly IRazorpayRepository _repository;
    private readonly ITenantRepository _tenantRepository;

    public PaymentConfigController(IRazorpayRepository repository, ITenantRepository tenantRepository)
    {
        _repository = repository;
        _tenantRepository = tenantRepository;
    }

    [HttpGet("tenants")]
    public async Task<IActionResult> GetTenants()
    {
        var tenants = await _tenantRepository.GetAllAsync();
        return Ok(ApiResponse<IEnumerable<Tenant>>.SuccessResponse(tenants));
    }

    [HttpGet]
    public async Task<IActionResult> GetAll()
    {
        var configs = await _repository.GetAllPaymentConfigsAsync();
        return Ok(ApiResponse<IEnumerable<TenantPaymentConfig>>.SuccessResponse(configs));
    }

    [HttpPost]
    public async Task<IActionResult> Upsert([FromBody] TenantPaymentConfig config)
    {
        if (config == null) return BadRequest(ApiResponse.FailureResponse("Invalid configuration data."));
        
        var id = await _repository.UpsertPaymentConfigAsync(config);
        config.Id = id;
        
        return Ok(ApiResponse<TenantPaymentConfig>.SuccessResponse(config));
    }

    [HttpDelete("{id}")]
    public async Task<IActionResult> Delete(int id)
    {
        var success = await _repository.DeletePaymentConfigAsync(id);
        if (success) return Ok(ApiResponse.SuccessResponse("Configuration deleted successfully."));
        return BadRequest(ApiResponse.FailureResponse("Failed to delete configuration."));
    }
}
