using AssociationManager.Shared.Models;
using System.Collections.Generic;
using System.Threading.Tasks;

namespace AssociationManager.Data.Interfaces;

/// <summary>
/// A specialized user repository for the Global (Corporate) schema.
/// Used for mapping users to Tenants in Option B Standalone architecture.
/// </summary>
public interface IGlobalUserRepository : IUserRepository
{
}
