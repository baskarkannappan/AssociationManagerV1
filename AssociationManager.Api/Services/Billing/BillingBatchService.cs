using AssociationManager.Data.Interfaces;
using AssociationManager.Shared.Models;
using AssociationManager.Shared.Enums;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;

namespace AssociationManager.Api.Services.Billing;

public class BillingBatchService
{
    private readonly IAssetRepository _assetRepository;
    private readonly ITariffRepository _tariffRepository;
    private readonly IInvoiceRepository _invoiceRepository;
    private readonly IEnumerable<IBillingStrategy> _strategies;

    public BillingBatchService(
        IAssetRepository assetRepository,
        ITariffRepository tariffRepository,
        IInvoiceRepository invoiceRepository,
        IEnumerable<IBillingStrategy> strategies)
    {
        _assetRepository = assetRepository;
        _tariffRepository = tariffRepository;
        _invoiceRepository = invoiceRepository;
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
        var existingInvoices = (await _invoiceRepository.GetAllAsync(tenantId, request.AssociationId))
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

        foreach (var asset in allAssets)
        {
            // Skip if already invoiced for this period
            if (existingInvoices.Any(i => i.AssetId == asset.AssetId)) continue;

            var assetAssignments = assignments.Where(a => a.AssetId == asset.AssetId && a.IsActive).ToList();
            if (!assetAssignments.Any()) continue;

            decimal totalAmount = 0;
            var descriptions = new List<string>();
            bool hasZeroAmountCharge = false;

            foreach (var aa in assetAssignments)
            {
                var layer = allLayers.FirstOrDefault(l => l.TariffLayerId == aa.TariffLayerId);
                if (layer == null) continue;

                var strategy = _strategies.FirstOrDefault(s => s.SupportedType == layer.CalculationType);
                if (strategy != null)
                {
                    var amount = strategy.Calculate(asset, layer, aa);
                    if (amount == 0 && layer.CalculationType == CalculationType.AreaBased)
                    {
                        hasZeroAmountCharge = true;
                        descriptions.Add($"{layer.Name}: ₹0 (Missing Area Metadata)");
                    }
                    else
                    {
                        totalAmount += amount;
                        descriptions.Add($"{layer.Name}: ₹{amount}");
                    }
                }
            }

            // Show in preview even if total is 0 IF it has assignments (to help user debug)
            if (totalAmount > 0 || hasZeroAmountCharge)
            {
                var invoiceDescription = string.Join(" | ", descriptions);
                
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
                        AssetName = asset.Name,
                        Title = $"Monthly Maintenance - {periodName}",
                        Description = invoiceDescription,
                        Amount = totalAmount,
                        DueDate = request.DueDate,
                        Status = "Unpaid",
                        CreatedDate = DateTime.UtcNow
                    };
                    await _invoiceRepository.CreateAsync(invoice);
                    result.InvoicesGenerated++;
                }

                result.TotalAmount += totalAmount;
            }
        }

        result.Message = request.DryRun 
            ? $"Preview generated for {result.Previews.Count} assets." 
            : $"Successfully generated {result.InvoicesGenerated} invoices for {periodName}.";

        return result;
    }

    private IEnumerable<Asset> Flatten(IEnumerable<Asset> assets)
    {
        foreach (var asset in assets)
        {
            yield return asset;
            foreach (var child in Flatten(asset.Children))
                yield return child;
        }
    }
}
