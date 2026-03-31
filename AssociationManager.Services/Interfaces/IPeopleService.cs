using AssociationManager.Shared.Models;
using System.Collections.Generic;
using System.Threading.Tasks;

namespace AssociationManager.Services.Interfaces;

public interface IPeopleService
{
    // Person management
    Task<Person?> GetPersonByIdAsync(int id, int? associationId = null);
    Task<IEnumerable<Person>> GetAllPeopleAsync(int? associationId = null);
    Task<int> CreatePersonAsync(Person person);
    Task<bool> UpdatePersonAsync(Person person);

    // Occupancy (Linking Person to Unit)
    Task<IEnumerable<Occupancy>> GetOccupancyByUnitAsync(int unitId);
    Task<IEnumerable<Occupancy>> GetOccupancyByUserIdAsync(int userId);
    Task<Occupancy?> GetOccupancyByIdAsync(int id);
    Task<int> AddOccupantAsync(Occupancy occupancy);
    Task<bool> UpdateOccupantAsync(Occupancy occupancy);
    Task<bool> RemoveOccupantAsync(int occupancyId, int? associationId = null);

    // Unit Assets
    Task<IEnumerable<Vehicle>> GetVehiclesByUnitAsync(int unitId);
    Task<Vehicle?> GetVehicleByIdAsync(int id);
    Task<int> AddVehicleAsync(Vehicle vehicle);
    Task<bool> UpdateVehicleAsync(Vehicle vehicle);
    Task<bool> RemoveVehicleAsync(int vehicleId, int? associationId = null);

    Task<IEnumerable<Pet>> GetPetsByUnitAsync(int unitId);
    Task<Pet?> GetPetByIdAsync(int id);
    Task<int> AddPetAsync(Pet pet);
    Task<bool> UpdatePetAsync(Pet pet);
    Task<bool> RemovePetAsync(int petId, int? associationId = null);

    Task<bool> IsPrimaryResidentForAssetAsync(int userId, int assetId);
}
