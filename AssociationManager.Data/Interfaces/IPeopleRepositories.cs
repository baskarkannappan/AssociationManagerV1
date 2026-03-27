using AssociationManager.Shared.Models;
using System.Collections.Generic;
using System.Threading.Tasks;

namespace AssociationManager.Data.Interfaces;

public interface IPersonRepository
{
    Task<Person?> GetByIdAsync(int id, int tenantId, int? associationId);
    Task<IEnumerable<Person>> GetAllAsync(int tenantId, int? associationId);
    Task<int> CreateAsync(Person person);
    Task<bool> UpdateAsync(Person person);
    Task<bool> DeleteAsync(int id, int tenantId, int? associationId);
}

public interface IOccupancyRepository
{
    Task<IEnumerable<Occupancy>> GetByAssetIdAsync(int assetId, int tenantId, int associationId);
    Task<IEnumerable<Occupancy>> GetByUserIdAsync(int userId, int tenantId, int associationId);
    Task<Occupancy?> GetByIdAsync(int id, int tenantId, int associationId);
    Task<int> CreateAsync(Occupancy occupancy);
    Task<bool> DeleteAsync(int id, int tenantId, int? associationId);
}
