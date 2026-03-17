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
    public async Task<IActionResult> GetAllPeople()
    {
        return Ok(await _peopleService.GetAllPeopleAsync());
    }

    [HttpPost]
    public async Task<IActionResult> CreatePerson([FromBody] Person person)
    {
        var id = await _peopleService.CreatePersonAsync(person);
        await _auditService.LogAsync("Create Person", "Person", id);
        return Ok(id);
    }

    [HttpGet("unit/{unitId}/occupants")]
    public async Task<IActionResult> GetOccupants(int unitId)
    {
        return Ok(await _peopleService.GetOccupancyByUnitAsync(unitId));
    }

    [HttpPost("occupancy")]
    public async Task<IActionResult> AddOccupant([FromBody] Occupancy occupancy)
    {
        var id = await _peopleService.AddOccupantAsync(occupancy);
        await _auditService.LogAsync("Add Occupant", "Occupancy", id);
        return Ok(id);
    }

    [HttpDelete("occupancy/{id}")]
    public async Task<IActionResult> RemoveOccupant(int id)
    {
        await _peopleService.RemoveOccupantAsync(id);
        await _auditService.LogAsync("Remove Occupant", "Occupancy", id);
        return NoContent();
    }

    [HttpGet("unit/{unitId}/vehicles")]
    public async Task<IActionResult> GetVehicles(int unitId)
    {
        return Ok(await _peopleService.GetVehiclesByUnitAsync(unitId));
    }

    [HttpPost("vehicles")]
    public async Task<IActionResult> AddVehicle([FromBody] Vehicle vehicle)
    {
        var id = await _peopleService.AddVehicleAsync(vehicle);
        await _auditService.LogAsync("Add Vehicle", "Vehicle", id);
        return Ok(id);
    }

    [HttpGet("unit/{unitId}/pets")]
    public async Task<IActionResult> GetPets(int unitId)
    {
        return Ok(await _peopleService.GetPetsByUnitAsync(unitId));
    }

    [HttpPost("pets")]
    public async Task<IActionResult> AddPet([FromBody] Pet pet)
    {
        var id = await _peopleService.AddPetAsync(pet);
        await _auditService.LogAsync("Add Pet", "Pet", id);
        return Ok(id);
    }

    [HttpDelete("vehicles/{id}")]
    public async Task<IActionResult> RemoveVehicle(int id)
    {
        await _peopleService.RemoveVehicleAsync(id);
        await _auditService.LogAsync("Remove Vehicle", "Vehicle", id);
        return NoContent();
    }

    [HttpDelete("pets/{id}")]
    public async Task<IActionResult> RemovePet(int id)
    {
        await _peopleService.RemovePetAsync(id);
        await _auditService.LogAsync("Remove Pet", "Pet", id);
        return NoContent();
    }
}
