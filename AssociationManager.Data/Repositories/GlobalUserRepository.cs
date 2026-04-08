using AssociationManager.Data.Interfaces;

namespace AssociationManager.Data.Repositories;

public class GlobalUserRepository : UserRepository, IGlobalUserRepository
{
    public GlobalUserRepository(DbConnectionFactory dbConnectionFactory) 
        : base(dbConnectionFactory, "corp")
    {
    }
}
