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
    private readonly IAssocUserRepository _assocUserRepository;
    private readonly ITenantContext _tenantContext;

    public PeopleService(
        IPersonRepository personRepository,
        IOccupancyRepository occupancyRepository,
        IVehicleRepository vehicleRepository,
        IPetRepository petRepository,
        IAssocUserRepository assocUserRepository,
        ITenantContext tenantContext)
    {
        _personRepository = personRepository;
        _occupancyRepository = occupancyRepository;
        _vehicleRepository = vehicleRepository;
        _petRepository = petRepository;
        _assocUserRepository = assocUserRepository;
        _tenantContext = tenantContext;
    }

    private int CurrentTenantId => _tenantContext.TenantId;
    private int CurrentAssociationId => _tenantContext.AssociationId;

    // Person management
    public async Task<Person?> GetPersonByIdAsync(int id, int? associationId = null) => await _personRepository.GetByIdAsync(id, CurrentTenantId, associationId ?? CurrentAssociationId);
    public async Task<IEnumerable<Person>> GetAllPeopleAsync(int? associationId = null) => await _personRepository.GetAllAsync(CurrentTenantId, associationId ?? CurrentAssociationId);
    public async Task<int> CreatePersonAsync(Person person)
    {
        person.TenantId = CurrentTenantId;
        person.AssociationId = CurrentAssociationId;
        return await _personRepository.CreateAsync(person);
    }
    public async Task<bool> UpdatePersonAsync(Person person)
    {
        person.TenantId = CurrentTenantId;
        person.AssociationId = CurrentAssociationId;
        return await _personRepository.UpdateAsync(person);
    }

    // Occupancy
    public async Task<IEnumerable<Occupancy>> GetOccupancyByUnitAsync(int unitId) => await _occupancyRepository.GetByAssetIdAsync(unitId, CurrentTenantId, CurrentAssociationId);
    public async Task<IEnumerable<Occupancy>> GetOccupancyByUserIdAsync(int userId) => await _occupancyRepository.GetByUserIdAsync(userId, CurrentTenantId, CurrentAssociationId);
    
    public async Task<int> AddOccupantAsync(Occupancy occupancy)
    {
        occupancy.TenantId = CurrentTenantId;
        occupancy.AssociationId = CurrentAssociationId;
        
        var id = await _occupancyRepository.CreateAsync(occupancy);

        // Provision user as Resident if email exists
        var person = await _personRepository.GetByIdAsync(occupancy.PersonId, CurrentTenantId, CurrentAssociationId);
        if (person != null && !string.IsNullOrEmpty(person.Email))
        {
            var user = await _assocUserRepository.GetByEmailAsync(person.Email);
            int userId;
            if (user == null)
            {
                // Create user in assoc schema
                userId = await _assocUserRepository.CreateAsync(new User
                {
                    Email = person.Email,
                    Name = $"{person.FirstName} {person.LastName}",
                    Role = "User", // Base role
                    CreatedDate = System.DateTime.UtcNow,
                    IsActive = true
                });
            }
            else
            {
                userId = user.UserId;
            }

            // Map user to the association as Resident
            await _assocUserRepository.AddUserToTenantAsync(userId, CurrentAssociationId, "Resident");
        }

        return id;
    }
    public async Task<bool> RemoveOccupantAsync(int occupancyId, int? associationId = null) => await _occupancyRepository.DeleteAsync(occupancyId, CurrentTenantId, associationId ?? CurrentAssociationId);

    // Vehicles
    public async Task<IEnumerable<Vehicle>> GetVehiclesByUnitAsync(int unitId) => await _vehicleRepository.GetByAssetIdAsync(unitId, CurrentTenantId, CurrentAssociationId);
    public async Task<int> AddVehicleAsync(Vehicle vehicle)
    {
        vehicle.TenantId = CurrentTenantId;
        vehicle.AssociationId = CurrentAssociationId;
        return await _vehicleRepository.CreateAsync(vehicle);
    }
    public async Task<bool> UpdateVehicleAsync(Vehicle vehicle)
    {
        vehicle.TenantId = CurrentTenantId;
        vehicle.AssociationId = CurrentAssociationId;
        return await _vehicleRepository.UpdateAsync(vehicle);
    }
    public async Task<bool> RemoveVehicleAsync(int vehicleId, int? associationId = null) => await _vehicleRepository.DeleteAsync(vehicleId, CurrentTenantId, associationId ?? CurrentAssociationId);

    // Pets
    public async Task<IEnumerable<Pet>> GetPetsByUnitAsync(int unitId) => await _petRepository.GetByAssetIdAsync(unitId, CurrentTenantId, CurrentAssociationId);
    public async Task<int> AddPetAsync(Pet pet)
    {
        pet.TenantId = CurrentTenantId;
        pet.AssociationId = CurrentAssociationId;
        return await _petRepository.CreateAsync(pet);
    }
    public async Task<bool> UpdatePetAsync(Pet pet)
    {
        pet.TenantId = CurrentTenantId;
        pet.AssociationId = CurrentAssociationId;
        return await _petRepository.UpdateAsync(pet);
    }
    public async Task<bool> RemovePetAsync(int petId, int? associationId = null) => await _petRepository.DeleteAsync(petId, CurrentTenantId, associationId ?? CurrentAssociationId);
}
