using AssociationManager.Shared.Models;
using System.Collections.Generic;
using System.Threading.Tasks;

namespace AssociationManager.Data.Interfaces;

public interface IAssocUserRepository : IUserRepository
{
    Task<bool> DeleteByAssociationIdAsync(int associationId);
}
