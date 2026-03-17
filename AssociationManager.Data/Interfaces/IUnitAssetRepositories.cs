using AssociationManager.Shared.Models;
using System.Collections.Generic;
using System.Threading.Tasks;

namespace AssociationManager.Data.Interfaces;

public interface IVehicleRepository
{
    Task<IEnumerable<Vehicle>> GetByAssetIdAsync(int assetId, int tenantId);
    Task<int> CreateAsync(Vehicle vehicle);
    Task<bool> UpdateAsync(Vehicle vehicle);
    Task<bool> DeleteAsync(int id, int tenantId);
}

public interface IPetRepository
{
    Task<IEnumerable<Pet>> GetByAssetIdAsync(int assetId, int tenantId);
    Task<int> CreateAsync(Pet pet);
    Task<bool> UpdateAsync(Pet pet);
    Task<bool> DeleteAsync(int id, int tenantId);
}
