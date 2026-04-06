using AssociationManager.Data.Interfaces;
using AssociationManager.Services.Interfaces;
using AssociationManager.Shared.Models;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;

namespace AssociationManager.Services.Implementations;

public class PlatformBillingService : IPlatformBillingService
{
    private readonly IPlatformBillingRepository _billingRepository;
    private readonly ISubscriptionService _subscriptionService;
    private readonly IPlatformAccountRepository _platformAccountRepository;
    private readonly IAssociationRepository _associationRepository;
    private readonly AssociationManager.Shared.Interfaces.ITenantContext _tenantContext;
    private readonly AssociationManager.Services.Razorpay.RazorpayClient _razorpayClient;

    public PlatformBillingService(
        IPlatformBillingRepository billingRepository, 
        ISubscriptionService subscriptionService,
        IPlatformAccountRepository platformAccountRepository,
        IAssociationRepository associationRepository,
        AssociationManager.Shared.Interfaces.ITenantContext tenantContext,
        AssociationManager.Services.Razorpay.RazorpayClient razorpayClient)
    {
        _billingRepository = billingRepository;
        _subscriptionService = subscriptionService;
        _platformAccountRepository = platformAccountRepository;
        _associationRepository = associationRepository;
        _tenantContext = tenantContext;
        _razorpayClient = razorpayClient;
    }

    public async Task<int> GenerateMonthlyBillsAsync(int? month = null, int? year = null)
    {
        int count = 0;
        var subscriptions = await _subscriptionService.GetAllSubscriptionsAsync();
        var allInvoices = await _billingRepository.GetAllInvoicesAsync();

        foreach (var sub in subscriptions.Where(s => s.Status == "Active"))
        {
            // If manual month/year provided, use that. Otherwise use current "due" logic.
            DateTime billingDate;
            if (month.HasValue && month.Value > 0 && year.HasValue && year.Value > 0)
            {
                billingDate = new DateTime(year.Value, month.Value, 1);
            }
            else
            {
                if (sub.NextBillingDate > DateTime.UtcNow) continue;
                billingDate = new DateTime(sub.NextBillingDate.Year, sub.NextBillingDate.Month, 1);
            }

            // Guard: Check if invoice already exists for this association and EXACT month/year
            // We strip time from BillingDate in DB comparison if needed, but our repository uses 1st of month.
            bool exists = allInvoices.Any(i => 
                i.AssociationId == sub.AssociationId && 
                i.BillingDate.Month == billingDate.Month && 
                i.BillingDate.Year == billingDate.Year);

            if (exists) continue;

            var amount = await _subscriptionService.CalculateNextBillAsync(sub.AssociationId);
            
            var invoice = new PlatformInvoice
            {
                AssociationId = sub.AssociationId,
                PlanId = sub.PlanId,
                Amount = amount,
                BillingDate = billingDate,
                DueDate = billingDate.AddDays(15),
                Status = "Unpaid"
            };

            await _billingRepository.CreateInvoiceAsync(invoice);
            
            // Only update next billing date if we are doing the automated "due" billing
            if (!month.HasValue)
            {
                sub.NextBillingDate = sub.NextBillingDate.AddMonths(1);
                await _subscriptionService.SubscribeAsync(sub.AssociationId, sub.PlanId);
            }
            
            count++;
        }

        return count;
    }

    public async Task<IEnumerable<PlatformInvoice>> GetInvoicesForAssociationAsync(int associationId)
    {
        return await _billingRepository.GetInvoicesByAssociationIdAsync(associationId);
    }

    public async Task<IEnumerable<PlatformInvoice>> GetAllInvoicesAsync()
    {
        return await _billingRepository.GetAllInvoicesAsync();
    }

    public async Task<bool> ProcessPaymentAsync(PlatformPayment payment)
    {
        var result = await _billingRepository.RecordPaymentAsync(payment);
        return result > 0;
    }

    public async Task<RazorpayOrderResponse> CreateOrderAsync(int invoiceId)
    {
        var invoices = await _billingRepository.GetAllInvoicesAsync();
        var invoice = invoices.FirstOrDefault(i => i.PlatformInvoiceId == invoiceId);
        if (invoice == null) throw new Exception("Invoice not found.");

        var association = await _associationRepository.GetByIdAsync(invoice.AssociationId, _tenantContext.TenantId);
        if (association == null || association.PlatformAccountId == null)
            throw new Exception("Association billing not configured (missing PlatformAccountId).");

        var account = await _platformAccountRepository.GetByIdAsync(association.PlatformAccountId.Value);
        if (account == null || string.IsNullOrEmpty(account.RazorpayKeyId) || string.IsNullOrEmpty(account.RazorpayKeySecret))
            throw new Exception("Platform billing account not configured with Razorpay keys.");

        var orderId = await _razorpayClient.CreateOrderAsync(
            invoice.Amount, 
            "INR", 
            $"PLAT-{invoice.PlatformInvoiceId}", 
            account.RazorpayKeyId, 
            account.RazorpayKeySecret);

        return new RazorpayOrderResponse
        {
            OrderId = orderId,
            Amount = (int)(invoice.Amount * 100),
            Currency = "INR",
            KeyId = account.RazorpayKeyId
        };
    }

    public async Task<bool> VerifyPaymentAsync(RazorpayVerifyRequest request)
    {
        if (request.InvoiceId == null) throw new Exception("InvoiceId is required for verification.");

        // 1. Find the invoice and its association
        var invoices = await _billingRepository.GetAllInvoicesAsync();
        var invoice = invoices.FirstOrDefault(i => i.PlatformInvoiceId == request.InvoiceId.Value);
        if (invoice == null) throw new Exception("Invoice not found.");

        // 2. Find the association and its keys
        var association = await _associationRepository.GetByIdAsync(invoice.AssociationId, _tenantContext.TenantId);
        if (association == null || association.PlatformAccountId == null)
            throw new Exception("Association billing not configured.");

        // 3. Find the platform account keys
        var account = await _platformAccountRepository.GetByIdAsync(association.PlatformAccountId.Value);
        if (account == null || string.IsNullOrEmpty(account.RazorpayKeySecret))
            throw new Exception("Platform billing account missing Razorpay secret.");

        // 4. Verify signature
        bool isValid = _razorpayClient.VerifySignature(
            request.RazorpayOrderId, 
            request.RazorpayPaymentId, 
            request.RazorpaySignature, 
            account.RazorpayKeySecret);

        if (isValid)
        {
            // 5. Update Status
            await _billingRepository.UpdateInvoiceStatusAsync(invoice.PlatformInvoiceId, "Paid");

            // 6. Record Payment
            var payment = new PlatformPayment
            {
                PlatformInvoiceId = invoice.PlatformInvoiceId,
                Amount = invoice.Amount,
                PaymentDate = DateTime.UtcNow,
                PaymentMethod = "Razorpay",
                TransactionRef = request.RazorpayPaymentId,
                Status = "Completed"
            };
            await _billingRepository.RecordPaymentAsync(payment);
            return true;
        }

        return false;
    }
    
    public async Task<PlatformAccount?> GetBillingAccountByAssociationIdAsync(int associationId)
    {
        var association = await _associationRepository.GetByIdAsync(associationId, _tenantContext.TenantId);
        if (association == null || association.PlatformAccountId == null) return null;
        
        return await _platformAccountRepository.GetByIdAsync(association.PlatformAccountId.Value);
    }
}
