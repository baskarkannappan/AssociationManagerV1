using AssociationManager.Shared.Models;
using System.Collections.Generic;
using System.Threading.Tasks;

namespace AssociationManager.Services.Interfaces;

public interface IPeopleService
{
    // Person management
    Task<Person?> GetPersonByIdAsync(int id);
    Task<IEnumerable<Person>> GetAllPeopleAsync();
    Task<int> CreatePersonAsync(Person person);
    Task<bool> UpdatePersonAsync(Person person);

    // Occupancy (Linking Person to Unit)
    Task<IEnumerable<Occupancy>> GetOccupancyByUnitAsync(int unitId);
    Task<int> AddOccupantAsync(Occupancy occupancy);
    Task<bool> RemoveOccupantAsync(int occupancyId);

    // Unit Assets
    Task<IEnumerable<Vehicle>> GetVehiclesByUnitAsync(int unitId);
    Task<int> AddVehicleAsync(Vehicle vehicle);
    Task<bool> UpdateVehicleAsync(Vehicle vehicle);
    Task<bool> RemoveVehicleAsync(int vehicleId);

    Task<IEnumerable<Pet>> GetPetsByUnitAsync(int unitId);
    Task<int> AddPetAsync(Pet pet);
    Task<bool> UpdatePetAsync(Pet pet);
    Task<bool> RemovePetAsync(int petId);
}
