using AssociationManager.Data.Interfaces;
using AssociationManager.Services.Interfaces;
using AssociationManager.Shared.Interfaces;
using AssociationManager.Shared.Models;
using System.Collections.Generic;
using System.Threading.Tasks;

namespace AssociationManager.Services.Implementations;

public class PeopleService : IPeopleService
{
    private readonly IPersonRepository _personRepository;
    private readonly IOccupancyRepository _occupancyRepository;
    private readonly IVehicleRepository _vehicleRepository;
    private readonly IPetRepository _petRepository;
    private readonly ITenantContext _tenantContext;

    public PeopleService(
        IPersonRepository personRepository,
        IOccupancyRepository occupancyRepository,
        IVehicleRepository vehicleRepository,
        IPetRepository petRepository,
        ITenantContext tenantContext)
    {
        _personRepository = personRepository;
        _occupancyRepository = occupancyRepository;
        _vehicleRepository = vehicleRepository;
        _petRepository = petRepository;
        _tenantContext = tenantContext;
    }

    private int CurrentTenantId => _tenantContext.TenantId;

    // Person management
    public async Task<Person?> GetPersonByIdAsync(int id) => await _personRepository.GetByIdAsync(id, CurrentTenantId);
    public async Task<IEnumerable<Person>> GetAllPeopleAsync() => await _personRepository.GetAllAsync(CurrentTenantId);
    public async Task<int> CreatePersonAsync(Person person)
    {
        person.TenantId = CurrentTenantId;
        return await _personRepository.CreateAsync(person);
    }
    public async Task<bool> UpdatePersonAsync(Person person)
    {
        person.TenantId = CurrentTenantId;
        return await _personRepository.UpdateAsync(person);
    }

    // Occupancy
    public async Task<IEnumerable<Occupancy>> GetOccupancyByUnitAsync(int unitId) => await _occupancyRepository.GetByAssetIdAsync(unitId, CurrentTenantId);
    public async Task<int> AddOccupantAsync(Occupancy occupancy)
    {
        occupancy.TenantId = CurrentTenantId;
        return await _occupancyRepository.CreateAsync(occupancy);
    }
    public async Task<bool> RemoveOccupantAsync(int occupancyId) => await _occupancyRepository.DeleteAsync(occupancyId, CurrentTenantId);

    // Vehicles
    public async Task<IEnumerable<Vehicle>> GetVehiclesByUnitAsync(int unitId) => await _vehicleRepository.GetByAssetIdAsync(unitId, CurrentTenantId);
    public async Task<int> AddVehicleAsync(Vehicle vehicle)
    {
        vehicle.TenantId = CurrentTenantId;
        return await _vehicleRepository.CreateAsync(vehicle);
    }
    public async Task<bool> UpdateVehicleAsync(Vehicle vehicle)
    {
        vehicle.TenantId = CurrentTenantId;
        return await _vehicleRepository.UpdateAsync(vehicle);
    }
    public async Task<bool> RemoveVehicleAsync(int vehicleId) => await _vehicleRepository.DeleteAsync(vehicleId, CurrentTenantId);

    // Pets
    public async Task<IEnumerable<Pet>> GetPetsByUnitAsync(int unitId) => await _petRepository.GetByAssetIdAsync(unitId, CurrentTenantId);
    public async Task<int> AddPetAsync(Pet pet)
    {
        pet.TenantId = CurrentTenantId;
        return await _petRepository.CreateAsync(pet);
    }
    public async Task<bool> UpdatePetAsync(Pet pet)
    {
        pet.TenantId = CurrentTenantId;
        return await _petRepository.UpdateAsync(pet);
    }
    public async Task<bool> RemovePetAsync(int petId) => await _petRepository.DeleteAsync(petId, CurrentTenantId);
}
