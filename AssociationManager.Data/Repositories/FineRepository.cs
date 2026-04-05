using AssociationManager.Data.Interfaces;
using AssociationManager.Shared.Models;
using Dapper;
using System.Data;
using System.Threading.Tasks;

namespace AssociationManager.Data.Repositories;

public class FineRepository : IFineRepository
{
    private readonly DbConnectionFactory _dbConnectionFactory;

    public FineRepository(DbConnectionFactory dbConnectionFactory)
    {
        _dbConnectionFactory = dbConnectionFactory;
    }

    public async Task<FineSettings?> GetByAssociationIdAsync(int associationId)
    {
        using var connection = _dbConnectionFactory.CreateConnection();
        return await connection.QueryFirstOrDefaultAsync<FineSettings>(
            "assoc.sp_FineSettings_Get",
            new { AssociationId = associationId },
            commandType: CommandType.StoredProcedure);
    }

    public async Task<bool> UpsertAsync(FineSettings settings, int userId)
    {
        using var connection = _dbConnectionFactory.CreateConnection();
        var parameters = new DynamicParameters();
        parameters.Add("@AssociationId", settings.AssociationId);
        parameters.Add("@TenantId", settings.TenantId);
        parameters.Add("@StrategyType", settings.StrategyType);
        parameters.Add("@FineValue", settings.FineValue);
        parameters.Add("@GracePeriodDays", settings.GracePeriodDays);
        parameters.Add("@IsCompounding", settings.IsCompounding);
        parameters.Add("@Frequency", settings.Frequency);
        parameters.Add("@UserId", userId);

        await connection.ExecuteAsync("assoc.sp_FineSettings_Upsert", parameters, commandType: CommandType.StoredProcedure);
        return true;
    }
}
