using AssociationManager.Data.Interfaces;
using AssociationManager.Services.Interfaces;
using AssociationManager.Shared.Models;
using AssociationManager.Shared.Enums;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;

namespace AssociationManager.Api.Services.Billing;

public class BillingBatchService
{
    private readonly IAssetRepository _assetRepository;
    private readonly ITariffRepository _tariffRepository;
    private readonly IFinanceService _financeService;
    private readonly IBillingBatchRepository _billingBatchRepository;
    private readonly IAuditService _auditService;
    private readonly IEnumerable<IBillingStrategy> _strategies;

    public BillingBatchService(
        IAssetRepository assetRepository,
        ITariffRepository tariffRepository,
        IFinanceService financeService,
        IBillingBatchRepository billingBatchRepository,
        IAuditService auditService,
        IEnumerable<IBillingStrategy> strategies)
    {
        _assetRepository = assetRepository;
        _tariffRepository = tariffRepository;
        _financeService = financeService;
        _billingBatchRepository = billingBatchRepository;
        _auditService = auditService;
        _strategies = strategies;
    }

    public async Task<InvoiceBatchResult> ProcessBatchAsync(InvoiceBatchRequest request, int tenantId)
    {
        var result = new InvoiceBatchResult();
        
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
                Status = "Committed",
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
                            Status = "Unpaid",
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

        return result;
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
