using AssociationManager.Shared.Models;
using System.Collections.Generic;
using System.Threading.Tasks;

namespace AssociationManager.Data.Interfaces;

public interface IPersonRepository
{
    Task<Person?> GetByIdAsync(int id, int tenantId);
    Task<IEnumerable<Person>> GetAllAsync(int tenantId);
    Task<int> CreateAsync(Person person);
    Task<bool> UpdateAsync(Person person);
    Task<bool> DeleteAsync(int id, int tenantId);
}

public interface IOccupancyRepository
{
    Task<IEnumerable<Occupancy>> GetByAssetIdAsync(int assetId, int tenantId);
    Task<int> CreateAsync(Occupancy occupancy);
    Task<bool> DeleteAsync(int id, int tenantId);
}
