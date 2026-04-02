using AssociationManager.Shared.Models;
using System.Collections.Generic;
using System.Threading.Tasks;

namespace AssociationManager.Data.Interfaces;

public interface IInvoiceRepository
{
    Task<Invoice?> GetByIdAsync(int id, int tenantId, int? associationId);
    Task<IEnumerable<Invoice>> GetAllAsync(int tenantId, int? associationId);
    Task<IEnumerable<Invoice>> GetByAssetIdAsync(int assetId, int tenantId, int? associationId);
    Task<PagedResult<Invoice>> GetPagedAsync(int tenantId, InvoiceSearchCriteria criteria);
    Task<(decimal TotalUnpaid, decimal Collected30Days)> GetSummaryStatsAsync(int tenantId, int? associationId = null, int? assetId = null, IEnumerable<int>? assetIds = null);
    Task<int> CreateAsync(Invoice invoice);
    Task<bool> UpdateStatusAsync(int id, string status, int tenantId, int? associationId);
    Task<bool> DeleteAsync(int id, int tenantId, int? associationId);
    
    // Line Items
    Task<IEnumerable<InvoiceLineItem>> GetLineItemsAsync(int invoiceId);
    Task<int> CreateLineItemAsync(InvoiceLineItem lineItem);
}
