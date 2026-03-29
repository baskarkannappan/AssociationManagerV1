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

    public PlatformBillingService(IPlatformBillingRepository billingRepository, ISubscriptionService subscriptionService)
    {
        _billingRepository = billingRepository;
        _subscriptionService = subscriptionService;
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
}
