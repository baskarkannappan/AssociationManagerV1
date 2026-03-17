using AssociationManager.Data.Interfaces;
using AssociationManager.Services.Interfaces;
using AssociationManager.Shared.Interfaces;
using AssociationManager.Shared.Models;
using System.Collections.Generic;
using System.Threading.Tasks;

namespace AssociationManager.Services.Implementations;

public class FinanceService : IFinanceService
{
    private readonly IInvoiceRepository _invoiceRepository;
    private readonly IPaymentRepository _paymentRepository;
    private readonly ITenantContext _tenantContext;

    public FinanceService(
        IInvoiceRepository invoiceRepository, 
        IPaymentRepository paymentRepository, 
        ITenantContext tenantContext)
    {
        _invoiceRepository = invoiceRepository;
        _paymentRepository = paymentRepository;
        _tenantContext = tenantContext;
    }

    private int CurrentTenantId => _tenantContext.TenantId;

    public async Task<Invoice?> GetInvoiceByIdAsync(int id)
    {
        return await _invoiceRepository.GetByIdAsync(id);
    }

    public async Task<IEnumerable<Invoice>> GetAllInvoicesAsync()
    {
        return await _invoiceRepository.GetAllAsync();
    }

    public async Task<IEnumerable<Invoice>> GetInvoicesByAssetIdAsync(int assetId)
    {
        return await _invoiceRepository.GetByAssetIdAsync(assetId);
    }

    public async Task<int> CreateInvoiceAsync(Invoice invoice)
    {
        invoice.TenantId = CurrentTenantId;
        return await _invoiceRepository.CreateAsync(invoice);
    }

    public async Task<bool> UpdateInvoiceStatusAsync(int id, string status)
    {
        return await _invoiceRepository.UpdateStatusAsync(id, status);
    }

    public async Task<bool> DeleteInvoiceAsync(int id)
    {
        return await _invoiceRepository.DeleteAsync(id);
    }

    public async Task<IEnumerable<Payment>> GetPaymentsAsync()
    {
        return await _paymentRepository.GetByTenantIdAsync(CurrentTenantId);
    }

    public async Task<int> CreatePaymentAsync(Payment payment)
    {
        payment.TenantId = CurrentTenantId;
        payment.UserId = _tenantContext.UserId;
        
        var id = await _paymentRepository.CreateAsync(payment);

        // If Payment is linked to an Invoice, potentially update invoice status
        if (payment.InvoiceId.HasValue)
        {
            await _invoiceRepository.UpdateStatusAsync(payment.InvoiceId.Value, "Paid");
        }

        return id;
    }
}
