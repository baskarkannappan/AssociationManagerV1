using AssociationManager.Data.Interfaces;
using AssociationManager.Services.Interfaces;
using AssociationManager.Shared.Models;
using AssociationManager.Shared.Enums;
using AssociationManager.Shared.Interfaces;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using Microsoft.Extensions.Caching.Distributed;
using Microsoft.Extensions.Configuration;
using System.Text.Json;
using System.Net.Http;
using Hangfire;

namespace AssociationManager.Services.Billing;

public class BillingBatchService
{
    private readonly IAssetRepository _assetRepository;
    private readonly ITariffRepository _tariffRepository;
    private readonly IFinanceService _financeService;
    private readonly IBillingBatchRepository _billingBatchRepository;
    private readonly IAssociationRepository _associationRepository;
    private readonly IAuditService _auditService;
    private readonly IEnumerable<IBillingStrategy> _strategies;
    private readonly ITenantContext _tenantContext;
    private readonly IConfiguration _config;
    private readonly IHttpClientFactory _httpClientFactory;
    private readonly IDistributedCache _cache;
    private readonly IInvoiceRepository _invoiceRepository;
    private readonly IAuditLogRepository _auditLogRepository;

    public BillingBatchService(
        IAssetRepository assetRepository,
        ITariffRepository tariffRepository,
        IFinanceService financeService,
        IBillingBatchRepository billingBatchRepository,
        IAssociationRepository associationRepository,
        IAuditService auditService,
        ITenantContext tenantContext,
        IEnumerable<IBillingStrategy> strategies,
        IConfiguration config,
        IHttpClientFactory httpClientFactory,
        IDistributedCache cache,
        IInvoiceRepository invoiceRepository,
        IAuditLogRepository auditLogRepository)
    {
        _assetRepository = assetRepository;
        _tariffRepository = tariffRepository;
        _financeService = financeService;
        _billingBatchRepository = billingBatchRepository;
        _associationRepository = associationRepository;
        _auditService = auditService;
        _tenantContext = tenantContext;
        _strategies = strategies;
        _config = config;
        _httpClientFactory = httpClientFactory;
        _cache = cache;
        _invoiceRepository = invoiceRepository;
        _auditLogRepository = auditLogRepository;
    }

    /// <summary>
    /// Entry point for Hangfire background jobs.
    /// Safely sets the tenant context before executing the batch.
    /// </summary>
    public async Task ExecuteBatchJobAsync(InvoiceBatchRequest request, int tenantId, string jobId)
    {
        // Set context if we are in a background execution environment
        if (_tenantContext is AssociationManager.Services.Implementations.BackgroundTenantContext bgContext)
        {
            bgContext.SetContext(tenantId, request.AssociationId);
        }

        var result = await ProcessBatchAsync(request, tenantId, jobId);
        
        // Store result in cache for the UI to fetch
        // Store result in cache for the UI to fetch
        if (request.DryRun)
        {
            try {
                var json = JsonSerializer.Serialize(result);
                var cacheKey = $"batch_preview_{jobId}";
                await _cache.SetStringAsync(cacheKey, json, new DistributedCacheEntryOptions 
                { 
                    AbsoluteExpirationRelativeToNow = TimeSpan.FromMinutes(30) 
                });
                Console.WriteLine($"[Diagnostic] Preview saved to Shared Redis Cache: {cacheKey}");
            } catch (Exception ex) {
                Console.WriteLine($"[Diagnostic] Failed to save to shared cache: {ex.Message}");
            }
        }

        // Notify client via SignalR that job is complete
        await NotifyCompletionAsync(request, tenantId, jobId, request.DryRun ? "PREVIEW_READY" : "BATCH_READY");
    }

    public async Task<InvoiceBatchResult> ProcessBatchAsync(InvoiceBatchRequest request, int tenantId, string jobId = "N/A")
    {
        var result = new InvoiceBatchResult();
        var sw = System.Diagnostics.Stopwatch.StartNew();
        
        // 0. Verify Association Status
        var association = await _associationRepository.GetByIdAsync(request.AssociationId, tenantId);
        Console.WriteLine($"[Perf] Step 0 - Verify Association: {sw.ElapsedMilliseconds}ms");
        if (association == null || association.Status != "Active")
        {
            result.Message = association == null 
                ? "Association not found." 
                : $"Billing is disabled for this association because its status is '{association.Status}'.";
            result.IsLocked = true;
            return result;
        }

        // 1. Fetch Assets
        sw.Restart();
        var allAssetsFlat = (await _assetRepository.GetAllFlatAsync(tenantId, request.AssociationId)).ToList();
        Console.WriteLine($"[Perf] Step 1 - Fetch {allAssetsFlat.Count} Assets: {sw.ElapsedMilliseconds}ms");
        
        // 2. Fetch all Tariffs and Assignments
        sw.Restart();
        var allLayers = (await _tariffRepository.GetLayersByAssociationIdAsync(request.AssociationId, tenantId)).ToList();
        Console.WriteLine($"[Perf] Step 2a - Bulk Fetch Tariff Layers ({allLayers.Count} layers): {sw.ElapsedMilliseconds}ms");
        
        sw.Restart();
        var assignments = (await _tariffRepository.GetActiveTariffsByTenantIdAsync(tenantId)).ToList();
        Console.WriteLine($"[Perf] Step 2b - Fetch {assignments.Count} Assignments: {sw.ElapsedMilliseconds}ms");

        // Build lookup dictionaries for O(1) access
        sw.Restart();
        var assignmentsByAssetId = assignments
            .Where(a => a.IsActive)
            .GroupBy(a => a.AssetId)
            .ToDictionary(g => g.Key, g => g.ToList());
        
        var layerLookup = allLayers.ToDictionary(l => l.TariffLayerId);

        var allAssets = allAssetsFlat.Where(a => assignmentsByAssetId.ContainsKey(a.AssetId)).ToList();
        result.TotalAssets = allAssets.Count;
        Console.WriteLine($"[Perf] Step 2c - Build Lookups & Filter ({allAssets.Count} billable): {sw.ElapsedMilliseconds}ms");

        // 3. Duplicate Prevention - Lightweight stored procedure call (avoids N+1 line item loading)
        sw.Restart();
        var periodName = new DateTime(request.Year, request.Month, 1).ToString("MMMM yyyy");
        var periodPattern = $"%Monthly Maintenance - {periodName}%";
        
        var existingAssetIds = await _invoiceRepository.GetInvoicedAssetIdsByPeriodAsync(tenantId, request.AssociationId, periodPattern);
        var invoicedAssetIds = new HashSet<int>(existingAssetIds);
        bool hasExistingInvoices = invoicedAssetIds.Count > 0;
        Console.WriteLine($"[Perf] Step 3 - Duplicate Check ({invoicedAssetIds.Count} existing): {sw.ElapsedMilliseconds}ms");
        sw.Restart();

        if (hasExistingInvoices)
        {
            result.IsLocked = true;
            result.Message = $"Billing period {periodName} is already locked.";
            
            if (!request.DryRun)
            {
                result.Message += " Any adjustments should be handled in the next cycle.";
                return result;
            }
        }

        int? batchId = null;
        if (!request.DryRun)
        {
            // Idempotency: Check if a "Draft" batch already exists for this period to prevent duplicates on retries
            var existingBatch = await _billingBatchRepository.GetDraftBatchAsync(request.AssociationId, request.Month, request.Year, tenantId);
            
            if (existingBatch != null)
            {
                batchId = existingBatch.BillingBatchId;
                Console.WriteLine($"[Idempotency] Reusing existing Draft Batch ID: {batchId}");
                
                // Reset totals for the retry
                await _billingBatchRepository.UpdateTotalsAsync(batchId.Value, 0, 0, tenantId, request.AssociationId);
            }
            else
            {
                var batch = new BillingBatch
                {
                    TenantId = tenantId,
                    AssociationId = request.AssociationId,
                    Month = request.Month,
                    Year = request.Year,
                    Status = "Draft",
                    TotalAmount = 0,
                    InvoicesGenerated = 0,
                    CreatedDate = DateTime.UtcNow
                };
                batchId = await _billingBatchRepository.CreateAsync(batch);
                Console.WriteLine($"[Idempotency] Created NEW Batch ID: {batchId}");
            }
        }

        try
        {
            var invoicesToCreate = new List<Invoice>();
            var lineItemsToCreate = new List<InvoiceLineItem>();
            var logsToCreate = new List<AuditLog>();
            var assetsProcessedInChunk = 0;
            const int chunkSize = 100; // Updated every 100 assets for performance and feedback
            var oneTimeChargesToDeactivate = new Dictionary<int, List<int>>(); // LayerId -> List of AssetIds

            foreach (var asset in allAssets)
            {
                // Skip if already invoiced for this period (O(1) lookup)
                if (invoicedAssetIds.Contains(asset.AssetId)) continue;

                // Get assignments for this asset (O(1) lookup)
                if (!assignmentsByAssetId.TryGetValue(asset.AssetId, out var assetAssignments) || !assetAssignments.Any()) continue;

                decimal assetTotalAmount = 0;
                var assetLineItems = new List<InvoiceLineItem>();
                bool hasZeroAmountCharge = false;
                var tempInvoiceId = Guid.NewGuid().ToString();

                foreach (var aa in assetAssignments)
                {
                    if (!layerLookup.TryGetValue(aa.TariffLayerId, out var layer)) continue;

                    var strategy = _strategies.FirstOrDefault(s => s.SupportedType == layer.CalculationType);
                    if (strategy != null)
                    {
                        var amount = strategy.Calculate(asset, layer, aa);
                        
                        var lineItem = new InvoiceLineItem
                        {
                            ChargeName = layer.Name,
                            Amount = amount,
                            Description = $"{layer.Name} calculation using {layer.CalculationType}",
                            TariffLayerId = layer.TariffLayerId,
                            Rate = layer.BaseRate,
                            TempId = tempInvoiceId
                        };

                        if (amount == 0 && layer.CalculationType == CalculationType.AreaBased)
                        {
                            hasZeroAmountCharge = true;
                            lineItem.Description += " (Missing Area Metadata)";
                        }
                        else
                        {
                            assetTotalAmount += amount;
                        }
                        
                        assetLineItems.Add(lineItem);
                    }
                }

                if (assetTotalAmount > 0 || hasZeroAmountCharge)
                {
                    var invoiceDescription = string.Join(" | ", assetLineItems.Select(l => $"{l.ChargeName}: ₹{l.Amount}"));
                    
                    result.Previews.Add(new InvoicePreviewItem
                    {
                        AssetId = asset.AssetId,
                        AssetName = asset.Name,
                        Amount = assetTotalAmount,
                        Description = invoiceDescription
                    });

                    if (!request.DryRun && assetTotalAmount > 0)
                    {
                        var invoice = new Invoice
                        {
                            TenantId = tenantId,
                            AssociationId = request.AssociationId,
                            AssetId = asset.AssetId,
                            BillingBatchId = batchId,
                            Title = $"Monthly Maintenance - {periodName}",
                            Description = invoiceDescription,
                            Amount = assetTotalAmount,
                            DueDate = request.DueDate,
                            Status = "Draft",
                            CreatedDate = DateTime.UtcNow,
                            TempId = tempInvoiceId
                        };

                        invoicesToCreate.Add(invoice);
                        lineItemsToCreate.AddRange(assetLineItems);

                        foreach (var line in assetLineItems)
                        {
                            logsToCreate.Add(new AuditLog
                            {
                                Action = $"Billed {line.ChargeName}: ₹{line.Amount} (Rate: ₹{line.Rate}, Logic: {line.Description})",
                                Entity = "Billing",
                                EntityId = 0, // Will be 0 in bulk insert but linked via InvoiceId mapping in SP
                                AssociationId = request.AssociationId,
                                AssetId = asset.AssetId,
                                TenantId = tenantId,
                                Timestamp = DateTime.UtcNow
                            });
                        }

                        // Collect One-Time Charges for Bulk Deactivation
                        foreach (var aa in assetAssignments)
                        {
                            if (!aa.IsRecurring)
                            {
                                if (!oneTimeChargesToDeactivate.ContainsKey(aa.TariffLayerId))
                                    oneTimeChargesToDeactivate[aa.TariffLayerId] = new List<int>();
                                
                                oneTimeChargesToDeactivate[aa.TariffLayerId].Add(asset.AssetId);

                                logsToCreate.Add(new AuditLog
                                {
                                    Action = $"Deactivated One-Time Charge: {aa.TariffLayerId}",
                                    Entity = "AssetTariff",
                                    EntityId = aa.AssetId,
                                    AssociationId = request.AssociationId,
                                    AssetId = asset.AssetId,
                                    TenantId = tenantId,
                                    Timestamp = DateTime.UtcNow
                                });
                            }
                        }

                        result.InvoicesGenerated++;
                        result.TotalAmount += assetTotalAmount;
                    }

                    assetsProcessedInChunk++;

                    // Flush Chunk
                    if (!request.DryRun && assetsProcessedInChunk >= chunkSize)
                    {
                        await _invoiceRepository.CreateBulkAsync(tenantId, request.AssociationId, invoicesToCreate, lineItemsToCreate);
                        await _auditLogRepository.CreateBulkAsync(tenantId, request.AssociationId, _tenantContext.UserId, logsToCreate);
                        
                        // Periodic Progress Update to UI
                        if (batchId.HasValue)
                        {
                            await _billingBatchRepository.UpdateTotalsAsync(batchId.Value, result.TotalAmount, result.InvoicesGenerated, tenantId, request.AssociationId);
                        }

                        invoicesToCreate.Clear();
                        lineItemsToCreate.Clear();
                        logsToCreate.Clear();
                        assetsProcessedInChunk = 0;
                        Console.WriteLine($"[Perf] Flushed chunk of {chunkSize} assets. Total generated: {result.InvoicesGenerated}");
                    }
                }
            }

            // Final Flush
            if (!request.DryRun && invoicesToCreate.Any())
            {
                await _invoiceRepository.CreateBulkAsync(tenantId, request.AssociationId, invoicesToCreate, lineItemsToCreate);
                await _auditLogRepository.CreateBulkAsync(tenantId, request.AssociationId, _tenantContext.UserId, logsToCreate);
                
                if (batchId.HasValue)
                {
                    await _billingBatchRepository.UpdateTotalsAsync(batchId.Value, result.TotalAmount, result.InvoicesGenerated, tenantId, request.AssociationId);
                }
                Console.WriteLine($"[Perf] Flushed final chunk. Total generated: {result.InvoicesGenerated}");
            }

            // Bulk Deactivate One-Time Charges at the end
            if (!request.DryRun && oneTimeChargesToDeactivate.Any())
            {
                sw.Restart();
                foreach (var layerKvp in oneTimeChargesToDeactivate)
                {
                    await _tariffRepository.DeactivateTariffsBulkAsync(layerKvp.Key, layerKvp.Value);
                }
                Console.WriteLine($"[Perf] Step 5 - Bulk Deactivated One-Time Charges ({oneTimeChargesToDeactivate.Values.Sum(v => v.Count)} total): {sw.ElapsedMilliseconds}ms");
            }
        }
        catch (Exception ex)
        {
            Console.WriteLine($"[Critical] Batch Generation Loop Failed: {ex.Message}");
            await _auditService.LogAsync($"Critical Batch Failure: {ex.Message}", "BillingBatch", batchId);
            throw; // Let Hangfire handle retry/failure state
        }
        finally
        {
            Console.WriteLine($"[Perf] Step 4 - Process {allAssets.Count} Assets Loop: {sw.ElapsedMilliseconds}ms (Generated {result.InvoicesGenerated} invoices, {result.Previews.Count} previews)");
            if (!request.DryRun)
            {
                await NotifyCompletionAsync(request, tenantId, jobId, "BATCH_READY");
            }
        }

        return result;
    }

    private async Task NotifyCompletionAsync(InvoiceBatchRequest request, int tenantId, string jobId, string status)
    {
        try
        {
            var baseUrl = _config["ApiSettings:GatewayUrl"];
            if (string.IsNullOrEmpty(baseUrl)) return;

            var client = _httpClientFactory.CreateClient();
            var period = $"{request.Month}-{request.Year}";
            var url = $"{baseUrl.TrimEnd('/')}/api/finance/batches/notify-completion?tenantId={tenantId}&associationId={request.AssociationId}&period={period}&jobId={jobId}&status={status}";
            
            Console.WriteLine($"[Diagnostic] Notifying UI/Gateway: {url}");
            var response = await client.PostAsync(url, null);
            Console.WriteLine($"[Diagnostic] Notification Result: {response.StatusCode}");
        }
        catch (Exception ex)
        {
            Console.WriteLine($"[Diagnostic] Notification Exception: {ex.Message}");
            // Log notify failure but don't fail the entire batch job
            await _auditService.LogAsync($"Failed to notify UI of batch completion: {ex.Message}", "System", 0);
        }
    }

    public async Task<IEnumerable<BillingBatch>> GetBatchesAsync(int associationId, int tenantId)
    {
        return await _billingBatchRepository.GetByAssociationAsync(associationId, tenantId);
    }

}
