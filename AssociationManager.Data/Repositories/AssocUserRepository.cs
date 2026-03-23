using AssociationManager.Data.Interfaces;
using AssociationManager.Shared.Models;
using Dapper;
using System.Data;
using System.Threading.Tasks;

namespace AssociationManager.Data.Repositories;

public class AssocUserRepository : UserRepository, IAssocUserRepository
{
    private readonly DbConnectionFactory _dbConnectionFactory;

    public AssocUserRepository(DbConnectionFactory dbConnectionFactory) 
        : base(dbConnectionFactory, "assoc")
    {
        _dbConnectionFactory = dbConnectionFactory;
    }

    public async Task<bool> DeleteByAssociationIdAsync(int associationId)
    {
        using var connection = _dbConnectionFactory.CreateConnection();
        return await connection.ExecuteAsync(
            "DELETE FROM assoc.UserAssociations WHERE AssociationId = @AssociationId",
            new { AssociationId = associationId }) >= 0;
    }
}
