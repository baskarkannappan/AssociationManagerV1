using AssociationManager.Data.Interfaces;
using AssociationManager.Shared.Models;
using Dapper;
using System.Collections.Generic;
using System.Data;
using System.Threading.Tasks;

namespace AssociationManager.Data.Repositories;

public class SubscriptionRepository : ISubscriptionRepository
{
    private readonly DbConnectionFactory _dbConnectionFactory;

    public SubscriptionRepository(DbConnectionFactory dbConnectionFactory)
    {
        _dbConnectionFactory = dbConnectionFactory;
    }

    public async Task<IEnumerable<SubscriptionPlan>> GetAllPlansAsync()
    {
        using var connection = _dbConnectionFactory.CreateConnection();
        return await connection.QueryAsync<SubscriptionPlan>(
            "corp.sp_SubscriptionPlans_GetAll",
            commandType: CommandType.StoredProcedure);
    }

    public async Task<AssociationSubscription?> GetByAssociationIdAsync(int associationId)
    {
        using var connection = _dbConnectionFactory.CreateConnection();
        return await connection.QueryFirstOrDefaultAsync<AssociationSubscription>(
            "corp.sp_Subscriptions_GetByAssociationId",
            new { associationId },
            commandType: CommandType.StoredProcedure);
    }

    public async Task<bool> UpsertSubscriptionAsync(AssociationSubscription subscription)
    {
        using var connection = _dbConnectionFactory.CreateConnection();
        return await connection.ExecuteAsync(
            "corp.sp_Subscriptions_Upsert",
            new { 
                subscription.AssociationId, 
                subscription.PlanId, 
                subscription.Status, 
                subscription.NextBillingDate 
            },
            commandType: CommandType.StoredProcedure) > 0;
    }

    public async Task<bool> UpsertPlanAsync(SubscriptionPlan plan)
    {
        using var connection = _dbConnectionFactory.CreateConnection();
        return await connection.ExecuteAsync(
            "corp.sp_SubscriptionPlans_Upsert",
            new { 
                plan.PlanId,
                plan.Name,
                plan.BasePrice,
                plan.PricePerAsset,
                plan.IsActive
            },
            commandType: CommandType.StoredProcedure) > 0;
    }
}
