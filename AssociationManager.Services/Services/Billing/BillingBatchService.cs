using AssociationManager.Data.Interfaces;
using AssociationManager.Services.Interfaces;
using AssociationManager.Shared.Models;
using AssociationManager.Shared.Enums;
using AssociationManager.Shared.Interfaces;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using Microsoft.Extensions.Configuration;
using System.Net.Http;

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
        IHttpClientFactory httpClientFactory)
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
    }

    /// <summary>
    /// Entry point for Hangfire background jobs.
    /// Safely sets the tenant context before executing the batch.
    /// </summary>
    public async Task ExecuteBatchJobAsync(InvoiceBatchRequest request, int tenantId)
    {
        // Set context if we are in a background execution environment
        if (_tenantContext is AssociationManager.Services.Implementations.BackgroundTenantContext bgContext)
        {
            bgContext.SetContext(tenantId, request.AssociationId);
        }

        await ProcessBatchAsync(request, tenantId);
    }

    public async Task<InvoiceBatchResult> ProcessBatchAsync(InvoiceBatchRequest request, int tenantId)
    {
        var result = new InvoiceBatchResult();
        
        // 0. Verify Association Status
        var association = await _associationRepository.GetByIdAsync(request.AssociationId, tenantId);
        if (association == null || association.Status != "Active")
        {
            result.Message = association == null 
                ? "Association not found." 
                : $"Billing is disabled for this association because its status is '{association.Status}'.";
            result.IsLocked = true;
            return result;
        }

        // 1. Fetch Assets
        var assets = (await _assetRepository.GetHierarchyAsync(tenantId, request.AssociationId)).ToList();
        // Include more asset types that might be billable
        var billableTypes = new[] { AssetType.Unit, AssetType.Villa, AssetType.Property, AssetType.Block, AssetType.Tower };
        var allAssets = Flatten(assets).Where(a => billableTypes.Contains(a.AssetType)).ToList();
        result.TotalAssets = allAssets.Count;

        // 2. Fetch all Tariffs and Assignments
        var groups = await _tariffRepository.GetGroupsByTenantIdAsync(tenantId, request.AssociationId);
        var allLayers = new List<TariffLayer>();
        foreach (var group in groups)
        {
            var layers = await _tariffRepository.GetLayersByGroupIdAsync(group.TariffGroupId);
            allLayers.AddRange(layers);
        }
        var assignments = (await _tariffRepository.GetActiveTariffsByTenantIdAsync(tenantId)).ToList();

        // 3. Fetch existing invoices for this period to avoid duplicates
        var existingInvoices = (await _financeService.GetAllInvoicesAsync(request.AssociationId))
            .Where(i => i.CreatedDate.Month == request.Month && i.CreatedDate.Year == request.Year && i.Title.Contains("Monthly Maintenance"))
            .ToList();

        var periodName = new DateTime(request.Year, request.Month, 1).ToString("MMMM yyyy");

        if (existingInvoices.Any())
        {
            result.IsLocked = true;
            if (!request.DryRun)
            {
                result.Message = $"Billing period {periodName} is already locked. Any adjustments should be handled in the next cycle.";
                return result;
            }
        }

        int? batchId = null;
        if (!request.DryRun)
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
        }

        foreach (var asset in allAssets)
        {
            // Skip if already invoiced for this period
            if (existingInvoices.Any(i => i.AssetId == asset.AssetId)) continue;

            var assetAssignments = assignments.Where(a => a.AssetId == asset.AssetId && a.IsActive).ToList();
            if (!assetAssignments.Any()) continue;

            decimal totalAmount = 0;
            var lineItems = new List<InvoiceLineItem>();
            bool hasZeroAmountCharge = false;

            foreach (var aa in assetAssignments)
            {
                var layer = allLayers.FirstOrDefault(l => l.TariffLayerId == aa.TariffLayerId);
                if (layer == null) continue;

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
                        Rate = layer.BaseRate // Point-in-time snapshot
                    };

                    if (amount == 0 && layer.CalculationType == CalculationType.AreaBased)
                    {
                        hasZeroAmountCharge = true;
                        lineItem.Description += " (Missing Area Metadata)";
                    }
                    else
                    {
                        totalAmount += amount;
                    }
                    
                    lineItems.Add(lineItem);
                }
            }

            try
            {
                // Show in preview even if total is 0 IF it has assignments (to help user debug)
                if (totalAmount > 0 || hasZeroAmountCharge)
                {
                    var invoiceDescription = string.Join(" | ", lineItems.Select(l => $"{l.ChargeName}: ₹{l.Amount}"));
                    
                    result.Previews.Add(new InvoicePreviewItem
                    {
                        AssetId = asset.AssetId,
                        AssetName = asset.Name,
                        Amount = totalAmount,
                        Description = invoiceDescription
                    });

                    if (!request.DryRun && totalAmount > 0)
                    {
                        var invoice = new Invoice
                        {
                            TenantId = tenantId,
                            AssociationId = request.AssociationId,
                            AssetId = asset.AssetId,
                            BillingBatchId = batchId,
                            Title = $"Monthly Maintenance - {periodName}",
                            Description = invoiceDescription,
                            Amount = totalAmount,
                            DueDate = request.DueDate,
                            Status = "Draft",
                            CreatedDate = DateTime.UtcNow
                        };
                        
                        // Persist Invoice and Line Items through FinanceService to ensure Ledger integrity
                        var invoiceId = await _financeService.CreateInvoiceAsync(invoice, lineItems);
                        
                        foreach (var line in lineItems)
                        {
                            // Introspection Log
                            await _auditService.LogAsync(
                                action: $"Billed {line.ChargeName}: ₹{line.Amount} (Rate: ₹{line.Rate}, Logic: {line.Description})",
                                entity: "Billing",
                                entityId: invoiceId,
                                associationId: request.AssociationId,
                                assetId: asset.AssetId
                            );
                        }

                        // Deactivate One-Time Charges
                        foreach (var aa in assetAssignments)
                        {
                            if (!aa.IsRecurring)
                            {
                                aa.IsActive = false;
                                await _tariffRepository.UpsertAssetTariffAsync(aa);
                                
                                await _auditService.LogAsync(
                                    action: $"Deactivated One-Time Charge: {aa.TariffLayerId}",
                                    entity: "AssetTariff",
                                    entityId: aa.AssetId,
                                    associationId: request.AssociationId,
                                    assetId: asset.AssetId
                                );
                            }
                        }
                        
                        result.InvoicesGenerated++;
                    }

                    result.TotalAmount += totalAmount;
                }
            }
            catch (Exception ex)
            {
                // Log failure for this asset and continue
                await _auditService.LogAsync(
                    action: $"Batch Generation Failed for Asset {asset.Name}: {ex.Message}",
                    entity: "BillingBatch",
                    entityId: batchId,
                    associationId: request.AssociationId,
                    assetId: asset.AssetId
                );
            }
        }

        if (!request.DryRun)
        {
            await NotifyCompletionAsync(request, tenantId);
        }

        return result;
    }

    private async Task NotifyCompletionAsync(InvoiceBatchRequest request, int tenantId)
    {
        try
        {
            var baseUrl = _config["ApiSettings:GatewayUrl"];
            if (string.IsNullOrEmpty(baseUrl)) return;

            var client = _httpClientFactory.CreateClient();
            var period = $"{request.Month}-{request.Year}";
            var url = $"{baseUrl.TrimEnd('/')}/api/finance/batches/notify-completion?tenantId={tenantId}&associationId={request.AssociationId}&period={period}";
            
            await client.PostAsync(url, null);
        }
        catch (Exception ex)
        {
            // Log notify failure but don't fail the entire batch job
            await _auditService.LogAsync($"Failed to notify UI of batch completion: {ex.Message}", "System", 0);
        }
    }

    public async Task<IEnumerable<BillingBatch>> GetBatchesAsync(int associationId, int tenantId)
    {
        return await _billingBatchRepository.GetByAssociationAsync(associationId, tenantId);
    }

    private IEnumerable<Asset> Flatten(IEnumerable<Asset> assets)
    {
        foreach (var asset in assets)
        {
            yield return asset;
            if (asset.Children != null)
            {
                foreach (var child in Flatten(asset.Children))
                    yield return child;
            }
        }
    }
}
