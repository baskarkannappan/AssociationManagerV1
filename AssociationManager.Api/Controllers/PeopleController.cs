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
[ApiController]
[Route("api/[controller]")]
public class PeopleController : ControllerBase
{
    private readonly IPeopleService _peopleService;
    private readonly IAuditService _auditService;

    public PeopleController(IPeopleService peopleService, IAuditService auditService)
    {
        _peopleService = peopleService;
        _auditService = auditService;
    }

    [HttpGet]
    [Authorize(Policy = "RequireUserManager")]
    public async Task<IActionResult> GetAllPeople([FromQuery] int? associationId = null)
    {
        var people = await _peopleService.GetAllPeopleAsync(associationId);
        return Ok(ApiResponse<IEnumerable<Person>>.SuccessResponse(people));
    }

    [HttpPost]
    [Authorize(Policy = "RequireUserManager")]
    public async Task<IActionResult> CreatePerson([FromBody] Person person)
    {
        var id = await _peopleService.CreatePersonAsync(person);
        await _auditService.LogAsync("Create Person", "Person", id);
        return Ok(ApiResponse<int>.SuccessResponse(id, "Person record created."));
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
        var id = await _peopleService.AddOccupantAsync(occupancy);
        await _auditService.LogAsync("Add Occupant", "Occupancy", id);
        return Ok(ApiResponse<int>.SuccessResponse(id, "Occupancy record added."));
    }

    [HttpDelete("occupancy/{id}")]
    public async Task<IActionResult> RemoveOccupant(int id)
    {
        await _peopleService.RemoveOccupantAsync(id);
        await _auditService.LogAsync("Remove Occupant", "Occupancy", id);
        return Ok(ApiResponse.SuccessResponse("Occupancy removed."));
    }

    [HttpGet("unit/{unitId}/vehicles")]
    [Authorize(Policy = "RequireResident")]
    public async Task<IActionResult> GetVehicles(int unitId)
    {
        var vehicles = await _peopleService.GetVehiclesByUnitAsync(unitId);
        return Ok(ApiResponse<IEnumerable<Vehicle>>.SuccessResponse(vehicles));
    }

    [HttpPost("vehicles")]
    [Authorize(Policy = "RequireUserManager")]
    public async Task<IActionResult> AddVehicle([FromBody] Vehicle vehicle)
    {
        var id = await _peopleService.AddVehicleAsync(vehicle);
        await _auditService.LogAsync("Add Vehicle", "Vehicle", id);
        return Ok(ApiResponse<int>.SuccessResponse(id, "Vehicle record added."));
    }

    [HttpGet("unit/{unitId}/pets")]
    [Authorize(Policy = "RequireResident")]
    public async Task<IActionResult> GetPets(int unitId)
    {
        var pets = await _peopleService.GetPetsByUnitAsync(unitId);
        return Ok(ApiResponse<IEnumerable<Pet>>.SuccessResponse(pets));
    }

    [HttpPost("pets")]
    [Authorize(Policy = "RequireUserManager")]
    public async Task<IActionResult> AddPet([FromBody] Pet pet)
    {
        var id = await _peopleService.AddPetAsync(pet);
        await _auditService.LogAsync("Add Pet", "Pet", id);
        return Ok(ApiResponse<int>.SuccessResponse(id, "Pet record added."));
    }

    [HttpDelete("vehicles/{id}")]
    public async Task<IActionResult> RemoveVehicle(int id)
    {
        await _peopleService.RemoveVehicleAsync(id);
        await _auditService.LogAsync("Remove Vehicle", "Vehicle", id);
        return Ok(ApiResponse.SuccessResponse("Vehicle removed."));
    }

    [HttpDelete("pets/{id}")]
    public async Task<IActionResult> RemovePet(int id)
    {
        await _peopleService.RemovePetAsync(id);
        await _auditService.LogAsync("Remove Pet", "Pet", id);
        return Ok(ApiResponse.SuccessResponse("Pet removed."));
    }
}
