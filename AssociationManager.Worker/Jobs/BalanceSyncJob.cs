using AssociationManager.Data.Interfaces;
using AssociationManager.Services.Interfaces;
using Microsoft.Extensions.Logging;
using System;
using System.Threading.Tasks;

namespace AssociationManager.Worker.Jobs;

public class BalanceSyncJob
{
    private readonly IAssociationRepository _associationRepository;
    private readonly ILedgerService _ledgerService;
    private readonly ILogger<BalanceSyncJob> _logger;

    public BalanceSyncJob(
        IAssociationRepository associationRepository, 
        ILedgerService ledgerService,
        ILogger<BalanceSyncJob> logger)
    {
        _associationRepository = associationRepository;
        _ledgerService = ledgerService;
        _logger = logger;
    }

    public async Task ProcessAllAssociationsAsync()
    {
        _logger.LogInformation("Starting Association Balance Synchronization Job at {Time}", DateTime.UtcNow);
        
        var associations = await _associationRepository.GetAllAsync();
        int successCount = 0;
        int failCount = 0;

        foreach (var assoc in associations)
        {
            try
            {
                await _ledgerService.SyncAssociationBalancesAsync(assoc.AssociationId, assoc.TenantId);
                successCount++;
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Failed to sync balances for Association {AssocId} (Tenant {TenantId})", assoc.AssociationId, assoc.TenantId);
                failCount++;
            }
        }

        _logger.LogInformation("Completed Balance Sync. Success: {Success}, Failed: {Failed}", successCount, failCount);
    }
}
