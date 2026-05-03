using AssociationManager.Api.Authorization;
using AssociationManager.Services.Interfaces;
using AssociationManager.Shared.Models;
using AssociationManager.Shared.Enums;
using AssociationManager.Shared.Interfaces;
using System.Linq;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using System.Collections.Generic;
using System.Threading.Tasks;

namespace AssociationManager.Api.Controllers;

[Authorize]
[ApiController]
[Route("api/[controller]")]
public class PeopleController : ControllerBase
{
    private readonly IPeopleService _peopleService;
    private readonly IAuditService _auditService;
    private readonly IRuleEngineService _ruleEngine;
    private readonly ITenantContext _tenantContext;
    private readonly ILogger<PeopleController> _logger;

    public PeopleController(IPeopleService peopleService, IAuditService auditService, IRuleEngineService ruleEngine, ITenantContext tenantContext, ILogger<PeopleController> logger)
    {
        _peopleService = peopleService;
        _auditService = auditService;
        _ruleEngine = ruleEngine;
        _tenantContext = tenantContext;
        _logger = logger;
    }

    private async Task<bool> IsAuthorizedForAsset(int assetId, string action = "Manage")
    {
        // 1. Prepare Security Context
        var securityContext = new SecurityContext
        {
            UserRole = string.Join(",", User.FindAll(System.Security.Claims.ClaimTypes.Role).Select(c => c.Value)),
            UserLevel = AppRole.GetMaxLevel(User.Claims),
            AssociationId = _tenantContext.AssociationId,
            AssetId = assetId,
            IsOwner = false,
            Action = action,
            Resource = "Asset"
        };
        
        // 2. Add Primary Resident context
        var userIdStr = User.FindFirst("UserId")?.Value;
        if (int.TryParse(userIdStr, out int userId))
        {
            securityContext.IsPrimaryResident = await _peopleService.IsPrimaryResidentForAssetAsync(userId, assetId);
        }

        // 3. Evaluate Rule via Rule Engine
        string workflowName = action == "Manage" ? "CanManageAsset" : "CanViewAsset";
        var result = await _ruleEngine.EvaluateRuleAsync(workflowName, securityContext);

        if (!result)
        {
            _logger.LogWarning("[People] Authorization failed for user {UserId} on asset {AssetId} for action {Action}. Level: {UserLevel}, Primary: {IsPrimary}", 
                _tenantContext.UserId, assetId, action, securityContext.UserLevel, securityContext.IsPrimaryResident);
        }

        return result;
    }

    [HttpGet("can-manage-unit/{assetId}")]
    public async Task<IActionResult> CanManageUnit(int assetId)
    {
        var result = await IsAuthorizedForAsset(assetId);
        return Ok(ApiResponse<bool>.SuccessResponse(result));
    }

    [HttpGet]
    [Authorize(Policy = "RequireUserManager")]
    public async Task<IActionResult> GetAllPeople([FromQuery] int? associationId = null)
    {
        var people = await _peopleService.GetAllPeopleAsync(associationId);
        return Ok(ApiResponse<IEnumerable<Person>>.SuccessResponse(people));
    }

    [HttpPost]
    public async Task<IActionResult> CreatePerson([FromBody] Person person)
    {
        var id = await _peopleService.CreatePersonAsync(person);
        await _auditService.LogAsync("Create Person", "Person", id);
        return Ok(ApiResponse<int>.SuccessResponse(id, "Person record created."));
    }

    [HttpPut("{id}")]
    public async Task<IActionResult> UpdatePerson(int id, [FromBody] Person person)
    {
        person.PersonId = id;
        var success = await _peopleService.UpdatePersonAsync(person);
        if (!success) return NotFound(ApiResponse.FailureResponse("Person not found."));
        await _auditService.LogAsync("Update Person", "Person", id);
        return Ok(ApiResponse.SuccessResponse("Person record updated."));
    }

    [HttpGet("my-occupancy")]
    public async Task<IActionResult> GetMyOccupancy()
    {
        var userIdStr = User.FindFirst("UserId")?.Value;
        if (int.TryParse(userIdStr, out int userId))
        {
            var occupancy = await _peopleService.GetOccupancyByUserIdAsync(userId);
            return Ok(ApiResponse<IEnumerable<Occupancy>>.SuccessResponse(occupancy));
        }
        return Unauthorized(ApiResponse.FailureResponse("User identity not found."));
    }

    [HttpGet("unit/{unitId}/occupants")]
    [Authorize(Policy = "RequireResident")]
    public async Task<IActionResult> GetOccupants(int unitId)
    {
        var occupants = await _peopleService.GetOccupancyByUnitAsync(unitId);
        return Ok(ApiResponse<IEnumerable<Occupancy>>.SuccessResponse(occupants));
    }

    [HttpPost("occupancy")]
    public async Task<IActionResult> AddOccupant([FromBody] Occupancy occupancy)
    {
        if (!await IsAuthorizedForAsset(occupancy.AssetId))
        {
            return Forbid();
        }

        var id = await _peopleService.AddOccupantAsync(occupancy);
        await _auditService.LogAsync("Add Occupant", "Occupancy", id);
        return Ok(ApiResponse<int>.SuccessResponse(id, "Occupancy record added."));
    }

    [HttpDelete("occupancy/{id}")]
    public async Task<IActionResult> RemoveOccupant(int id)
    {
        var occupancy = await _peopleService.GetOccupancyByIdAsync(id);
        if (occupancy == null) return NotFound();

        if (!await IsAuthorizedForAsset(occupancy.AssetId))
        {
            return Forbid();
        }

        await _peopleService.RemoveOccupantAsync(id);
        await _auditService.LogAsync("Remove Occupant", "Occupancy", id);
        return Ok(ApiResponse.SuccessResponse("Occupancy removed."));
    }

    [HttpPut("occupancy/{id}")]
    public async Task<IActionResult> UpdateOccupant(int id, [FromBody] Occupancy occupancy)
    {
        if (!await IsAuthorizedForAsset(occupancy.AssetId))
        {
            return Forbid();
        }

        occupancy.OccupancyId = id;
        var success = await _peopleService.UpdateOccupantAsync(occupancy);
        if (!success) return NotFound();
        
        await _auditService.LogAsync("Update Occupant", "Occupancy", id);
        return Ok(ApiResponse.SuccessResponse("Occupancy updated."));
    }

    [HttpGet("unit/{unitId}/vehicles")]
    [Authorize(Policy = "RequireResident")]
    public async Task<IActionResult> GetVehicles(int unitId)
    {
        var vehicles = await _peopleService.GetVehiclesByUnitAsync(unitId);
        return Ok(ApiResponse<IEnumerable<Vehicle>>.SuccessResponse(vehicles));
    }

    [HttpPost("vehicles")]
    public async Task<IActionResult> AddVehicle([FromBody] Vehicle vehicle)
    {
        if (!await IsAuthorizedForAsset(vehicle.AssetId))
        {
            return Forbid();
        }

        var id = await _peopleService.AddVehicleAsync(vehicle);
        await _auditService.LogAsync("Add Vehicle", "Vehicle", id);
        return Ok(ApiResponse<int>.SuccessResponse(id, "Vehicle record added."));
    }

    [HttpDelete("vehicles/{id}")]
    public async Task<IActionResult> RemoveVehicle(int id)
    {
        var vehicle = await _peopleService.GetVehicleByIdAsync(id);
        if (vehicle == null) return NotFound();

        if (!await IsAuthorizedForAsset(vehicle.AssetId))
        {
            return Forbid();
        }

        await _peopleService.RemoveVehicleAsync(id);
        await _auditService.LogAsync("Remove Vehicle", "Vehicle", id);
        return Ok(ApiResponse.SuccessResponse("Vehicle removed."));
    }

    [HttpPut("vehicles/{id}")]
    public async Task<IActionResult> UpdateVehicle(int id, [FromBody] Vehicle vehicle)
    {
        var existing = await _peopleService.GetVehicleByIdAsync(id);
        if (existing == null) return NotFound();

        if (!await IsAuthorizedForAsset(existing.AssetId))
        {
            return Forbid();
        }

        vehicle.VehicleId = id;
        vehicle.AssetId = existing.AssetId; // Ensure asset remains the same
        var success = await _peopleService.UpdateVehicleAsync(vehicle);
        if (!success) return NotFound();

        await _auditService.LogAsync("Update Vehicle", "Vehicle", id);
        return Ok(ApiResponse.SuccessResponse("Vehicle updated."));
    }

    [HttpGet("unit/{unitId}/pets")]
    [Authorize(Policy = "RequireResident")]
    public async Task<IActionResult> GetPets(int unitId)
    {
        var pets = await _peopleService.GetPetsByUnitAsync(unitId);
        return Ok(ApiResponse<IEnumerable<Pet>>.SuccessResponse(pets));
    }

    [HttpPost("pets")]
    public async Task<IActionResult> AddPet([FromBody] Pet pet)
    {
        if (!await IsAuthorizedForAsset(pet.AssetId))
        {
            return Forbid();
        }

        var id = await _peopleService.AddPetAsync(pet);
        await _auditService.LogAsync("Add Pet", "Pet", id);
        return Ok(ApiResponse<int>.SuccessResponse(id, "Pet record added."));
    }

    [HttpDelete("pets/{id}")]
    public async Task<IActionResult> RemovePet(int id)
    {
        var pet = await _peopleService.GetPetByIdAsync(id);
        if (pet == null) return NotFound();

        if (!await IsAuthorizedForAsset(pet.AssetId))
        {
            return Forbid();
        }

        await _peopleService.RemovePetAsync(id);
        await _auditService.LogAsync("Remove Pet", "Pet", id);
        return Ok(ApiResponse.SuccessResponse("Pet removed."));
    }

    [HttpPut("pets/{id}")]
    public async Task<IActionResult> UpdatePet(int id, [FromBody] Pet pet)
    {
        var existing = await _peopleService.GetPetByIdAsync(id);
        if (existing == null) return NotFound();

        if (!await IsAuthorizedForAsset(existing.AssetId))
        {
            return Forbid();
        }

        pet.PetId = id;
        pet.AssetId = existing.AssetId; // Ensure asset remains the same
        var success = await _peopleService.UpdatePetAsync(pet);
        if (!success) return NotFound();

        await _auditService.LogAsync("Update Pet", "Pet", id);
        return Ok(ApiResponse.SuccessResponse("Pet updated."));
    }
}
