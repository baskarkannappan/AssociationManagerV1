using AssociationManager.Data.Interfaces;
using AssociationManager.Shared.Interfaces;
using AssociationManager.Shared.Models;
using Dapper;
using System.Collections.Generic;
using System.Data;
using System.Threading.Tasks;

namespace AssociationManager.Data.Repositories;

public class PaymentRepository : IPaymentRepository
{
    private readonly DbConnectionFactory _dbConnectionFactory;
    private readonly ITenantContext _tenantContext;

    public PaymentRepository(DbConnectionFactory dbConnectionFactory, ITenantContext tenantContext)
    {
        _dbConnectionFactory = dbConnectionFactory;
        _tenantContext = tenantContext;
    }

    public async Task<Payment?> GetByIdAsync(int id, int tenantId, int? associationId)
    {
        using var connection = _dbConnectionFactory.CreateConnection();
        return await connection.QueryFirstOrDefaultAsync<Payment>(
            "assoc.sp_Payments_GetById", 
            new { Id = id, TenantId = tenantId, AssociationId = associationId },
            commandType: CommandType.StoredProcedure);
    }

    public async Task<IEnumerable<Payment>> GetByTenantIdAsync(int tenantId, int? associationId)
    {
        using var connection = _dbConnectionFactory.CreateConnection();
        return await connection.QueryAsync<Payment>(
            "assoc.sp_Payments_GetByTenantId", 
            new { TenantId = tenantId, AssociationId = associationId },
            commandType: CommandType.StoredProcedure);
    }

    public async Task<int> CreateAsync(Payment payment)
    {
        payment.TenantId = _tenantContext.TenantId;
        payment.AssociationId = _tenantContext.AssociationId;
        using var connection = _dbConnectionFactory.CreateConnection();
        return await connection.ExecuteScalarAsync<int>(
            "assoc.sp_Payments_Create", 
            new 
            { 
                payment.TenantId, 
                payment.AssociationId, 
                payment.AssetId,
                payment.UserId, 
                payment.InvoiceId,
                payment.Amount, 
                payment.Currency, 
                payment.Status, 
                payment.CreatedDate, 
                payment.Notes,
                payment.GatewayReference 
            },
            commandType: CommandType.StoredProcedure);
    }

    public async Task<bool> UpdateStatusAsync(int id, string status, string? gatewayReference, int tenantId, int? associationId)
    {
        using var connection = _dbConnectionFactory.CreateConnection();
        return await connection.ExecuteAsync(
            "assoc.sp_Payments_UpdateStatus", 
            new { Id = id, Status = status, GatewayReference = gatewayReference, TenantId = tenantId, AssociationId = associationId },
            commandType: CommandType.StoredProcedure) > 0;
    }

    public async Task<bool> AutoSettleAsync(int assetId, int tenantId, int associationId, int userId)
    {
        using var connection = _dbConnectionFactory.CreateConnection();
        await connection.ExecuteAsync(
            "assoc.sp_Finance_AutoSettleInvoices", 
            new { AssetId = assetId, TenantId = tenantId, AssociationId = associationId, UserId = userId },
            commandType: CommandType.StoredProcedure);
        return true;
    }

    public async Task<(decimal TotalOutstanding, decimal TotalCredits, int UnitsWithCredit)> GetAssociationSummaryAsync(int tenantId, int associationId)
    {
        using var connection = _dbConnectionFactory.CreateConnection();
        var result = await connection.QueryFirstOrDefaultAsync(
            "assoc.sp_Finance_GetAssociationSummary", 
            new { TenantId = tenantId, AssociationId = associationId },
            commandType: CommandType.StoredProcedure);

        if (result != null)
        {
            return (
                (decimal)result.TotalOutstanding,
                (decimal)result.TotalAdvanceCredits,
                (int)result.UnitsWithCredit
            );
        }

        return (0, 0, 0);
    }

    public async Task<IEnumerable<AdvancePaymentHistory>> GetAdvancesAsync(int tenantId, int associationId, int? userId = null, int? assetId = null)
    {
        using var connection = _dbConnectionFactory.CreateConnection();
        return await connection.QueryAsync<AdvancePaymentHistory>(
            "assoc.sp_Payments_GetAdvances", 
            new { TenantId = tenantId, AssociationId = associationId, UserId = userId, AssetId = assetId },
            commandType: CommandType.StoredProcedure);
    }

    public async Task<PagedResult<AdvancePaymentHistory>> GetAdvancesPagedAsync(AdvanceSearchCriteria criteria)
    {
        using var connection = _dbConnectionFactory.CreateConnection();
        var parameters = new DynamicParameters();
        parameters.Add("@TenantId", criteria.TenantId);
        parameters.Add("@AssociationId", criteria.AssociationId);
        parameters.Add("@UserId", criteria.UserId);
        parameters.Add("@AssetId", criteria.AssetId);
        parameters.Add("@SearchTerm", criteria.SearchTerm);
        parameters.Add("@Status", criteria.Status);
        parameters.Add("@StartDate", criteria.StartDate);
        parameters.Add("@EndDate", criteria.EndDate);
        parameters.Add("@PageNumber", criteria.PageNumber);
        parameters.Add("@PageSize", criteria.PageSize);
        parameters.Add("@SortColumn", criteria.SortColumn);
        parameters.Add("@SortDirection", criteria.SortDirection);

        var result = new PagedResult<AdvancePaymentHistory>
        {
            PageNumber = criteria.PageNumber,
            PageSize = criteria.PageSize
        };

        var items = await connection.QueryAsync<dynamic>(
            "assoc.sp_Payments_GetAdvancesPaged", 
            parameters, 
            commandType: CommandType.StoredProcedure);

        var history = new List<AdvancePaymentHistory>();
        foreach (var row in items)
        {
            if (result.TotalCount == 0)
            {
                result.TotalCount = row.TotalCount;
            }

            history.Add(new AdvancePaymentHistory
            {
                Amount = row.Amount,
                Date = row.Date,
                Status = row.Status,
                ReferenceId = row.ReferenceId,
                ResidentName = row.ResidentName,
                UnitName = row.UnitName
            });
        }
        
        result.Items = history;
        result.FilteredCount = result.TotalCount;

        return result;
    }
}
