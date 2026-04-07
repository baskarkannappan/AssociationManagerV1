using AssociationManager.Data.Interfaces;
using AssociationManager.Shared.Models;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using System;
using System.Collections.Generic;
using System.Threading.Tasks;

namespace AssociationManager.Corporate.Api.Controllers;

[Authorize(Policy = "RequirePlatformAdmin")]
[ApiController]
[Route("api/[controller]")]
public class PlatformAccountsController : ControllerBase
{
    private readonly IPlatformAccountRepository _repository;

    public PlatformAccountsController(IPlatformAccountRepository repository)
    {
        _repository = repository;
    }

    [HttpGet]
    public async Task<IActionResult> GetAll()
    {
        var accounts = await _repository.GetAllAsync();
        return Ok(ApiResponse<IEnumerable<PlatformAccount>>.SuccessResponse(accounts));
    }

    [HttpGet("{id}")]
    public async Task<IActionResult> GetById(int id)
    {
        var account = await _repository.GetByIdAsync(id);
        if (account == null) return NotFound(ApiResponse.FailureResponse("Account not found."));
        return Ok(ApiResponse<PlatformAccount>.SuccessResponse(account));
    }

    [HttpPost]
    public async Task<IActionResult> Create([FromBody] PlatformAccount account)
    {
        var id = await _repository.CreateAsync(account);
        return CreatedAtAction(nameof(GetById), new { id }, ApiResponse<int>.SuccessResponse(id, "Platform account created successfully."));
    }

    [HttpPut("{id}")]
    public async Task<IActionResult> Update(int id, [FromBody] PlatformAccount account)
    {
        account.Id = id;
        var success = await _repository.UpdateAsync(account);
        if (!success) return NotFound(ApiResponse.FailureResponse("Account not found for update."));
        return Ok(ApiResponse.SuccessResponse("Platform account updated successfully."));
    }

    [HttpDelete("{id}")]
    public async Task<IActionResult> Delete(int id)
    {
        var success = await _repository.DeleteAsync(id);
        if (!success) return NotFound(ApiResponse.FailureResponse("Account not found for deletion."));
        return Ok(ApiResponse.SuccessResponse("Platform account deleted successfully."));
    }
}
