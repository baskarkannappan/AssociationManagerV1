using AssociationManager.Shared.Models;
using System.Threading.Tasks;

namespace AssociationManager.Data.Interfaces;

public interface IFineRepository
{
    Task<FineSettings?> GetByAssociationIdAsync(int associationId);
    Task<bool> UpsertAsync(FineSettings settings, int userId);
}
