using AssociationManager.Data.Interfaces;
using AssociationManager.Services.Interfaces;
using AssociationManager.Shared.Interfaces;
using AssociationManager.Shared.Models;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace AssociationManager.Services.Implementations;

public class EmailTemplateService : IEmailTemplateService
{
    private readonly IInvoiceRepository _invoiceRepository;
    private readonly IAssociationRepository _associationRepository;
    private readonly IAssetRepository _assetRepository;
    private readonly IOccupancyRepository _occupancyRepository;
    private readonly IPersonRepository _personRepository;
    private readonly IFineService _fineService;
    private readonly ITenantContext _tenantContext;

    public EmailTemplateService(
        IInvoiceRepository invoiceRepository,
        IAssociationRepository associationRepository,
        IAssetRepository assetRepository,
        IOccupancyRepository occupancyRepository,
        IPersonRepository personRepository,
        IFineService fineService,
        ITenantContext tenantContext)
    {
        _invoiceRepository = invoiceRepository;
        _associationRepository = associationRepository;
        _assetRepository = assetRepository;
        _occupancyRepository = occupancyRepository;
        _personRepository = personRepository;
        _fineService = fineService;
        _tenantContext = tenantContext;
    }

    public async Task<string> GenerateInvoiceHtmlAsync(int invoiceId)
    {
        // 1. Fetch Data (Identical to PdfService logic)
        var associationId = _tenantContext.AssociationId > 0 ? (int?)_tenantContext.AssociationId : null;
        var invoice = await _invoiceRepository.GetByIdAsync(invoiceId, _tenantContext.TenantId, associationId);
        if (invoice == null) throw new Exception("Invoice not found.");

        var persistedLineItems = await _invoiceRepository.GetLineItemsAsync(invoiceId);
        var association = await _associationRepository.GetByIdAsync(invoice.AssociationId, invoice.TenantId);
        var bankDetails = await _associationRepository.GetBankDetailsAsync(invoice.AssociationId, invoice.TenantId);

        string residentName = "Resident";
        string assetName = invoice.AssetName ?? "Unit";

        if (invoice.AssetId.HasValue)
        {
            var asset = await _assetRepository.GetByIdAsync(invoice.AssetId.Value, invoice.TenantId, invoice.AssociationId);
            if (asset != null) assetName = asset.Name;

            var occupancies = await _occupancyRepository.GetByAssetIdAsync(invoice.AssetId.Value, invoice.TenantId, invoice.AssociationId);
            var primary = occupancies.FirstOrDefault(o => o.IsPrimaryContact) ?? occupancies.FirstOrDefault();
            if (primary != null)
            {
                var person = await _personRepository.GetByIdAsync(primary.PersonId, invoice.TenantId, invoice.AssociationId);
                if (person != null) residentName = $"{person.FirstName} {person.LastName}";
            }
        }

        var itemsList = persistedLineItems.ToList();
        if (invoice.Status != "Paid" && invoice.DueDate < DateTime.UtcNow)
        {
            var fine = await _fineService.CalculateFineAsync(invoice, DateTime.UtcNow);
            if (fine > 0 && !itemsList.Any(l => l.ChargeName.Contains("Penalty") || l.ChargeName.Contains("Fine")))
            {
                itemsList.Add(new InvoiceLineItem { ChargeName = "Late Penalty (Automated)", Amount = fine, Description = "Late payment charge." });
            }
        }

        decimal principalLineItems = itemsList.Where(l => !l.ChargeName.Contains("Penalty") && !l.ChargeName.Contains("Fine")).Sum(l => l.Amount);
        decimal penaltyLineItems = itemsList.Where(l => l.ChargeName.Contains("Penalty") || l.ChargeName.Contains("Fine")).Sum(l => l.Amount);
        decimal truePrincipal = Math.Max(invoice.Amount, principalLineItems);
        decimal totalAmount = truePrincipal + penaltyLineItems;

        string FormatCurrency(decimal amount) => amount.ToString("C", new System.Globalization.CultureInfo("en-IN"));

        // 2. Build HTML
        var sb = new StringBuilder();
        sb.Append("<div style='font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto; padding: 20px; border: 1px solid #f0f0f0; border-radius: 8px;'>");
        
        // Header
        sb.Append("<div style='display: flex; justify-content: space-between; align-items: start; margin-bottom: 30px;'>");
        sb.Append("<div>");
        sb.Append($"<h1 style='color: #007bff; margin: 0;'>{association?.Name ?? "Association Manager"}</h1>");
        sb.Append($"<p style='color: #666; font-size: 14px; margin: 5px 0;'>{association?.Description ?? "Community Management"}</p>");
        sb.Append("</div>");
        sb.Append("<div style='text-align: right;'>");
        sb.Append("<h2 style='margin: 0; font-size: 18px;'>INVOICE</h2>");
        sb.Append($"<p style='margin: 5px 0; color: #666;'>#{invoice.InvoiceId}</p>");
        sb.Append("</div>");
        sb.Append("</div>");

        // Billing Info
        sb.Append("<div style='margin-bottom: 30px;'>");
        sb.Append("<table style='width: 100%; font-size: 14px;'>");
        sb.Append("<tr>");
        sb.Append("<td style='vertical-align: top;'>");
        sb.Append("<strong>Bill To:</strong><br/>");
        sb.Append($"{residentName}<br/>");
        sb.Append($"{assetName}");
        sb.Append("</td>");
        sb.Append("<td style='text-align: right; vertical-align: top;'>");
        sb.Append($"<strong>Date:</strong> {invoice.CreatedDate:MMM dd, yyyy}<br/>");
        sb.Append($"<strong>Due Date:</strong> <span style='color: #dc3545;'>{invoice.DueDate:MMM dd, yyyy}</span>");
        sb.Append("</td>");
        sb.Append("</tr>");
        sb.Append("</table>");
        sb.Append("</div>");

        // Table
        sb.Append("<table style='width: 100%; border-collapse: collapse; margin-bottom: 30px; font-size: 14px;'>");
        sb.Append("<tr style='background-color: #f8f9fa; border-bottom: 2px solid #dee2e6;'>");
        sb.Append("<th style='padding: 10px; text-align: left;'>Description</th>");
        sb.Append("<th style='padding: 10px; text-align: right;'>Amount</th>");
        sb.Append("</tr>");

        foreach (var item in itemsList)
        {
            sb.Append("<tr style='border-bottom: 1px solid #eee;'>");
            sb.Append("<td style='padding: 10px;'>");
            sb.Append($"<div style='font-weight: bold;'>{item.ChargeName}</div>");
            if (!string.IsNullOrEmpty(item.Description)) sb.Append($"<div style='color: #666; font-size: 12px;'>{item.Description}</div>");
            sb.Append("</td>");
            sb.Append($"<td style='padding: 10px; text-align: right;'>{FormatCurrency(item.Amount)}</td>");
            sb.Append("</tr>");
        }

        sb.Append("<tr>");
        sb.Append("<td style='padding: 15px 10px; text-align: right;'><strong>Total Amount</strong></td>");
        sb.Append($"<td style='padding: 15px 10px; text-align: right; color: #007bff; font-size: 18px; font-weight: bold;'>{FormatCurrency(totalAmount)}</td>");
        sb.Append("</tr>");
        sb.Append("</table>");

        // Overdue Warning
        if (invoice.Status == "Overdue")
        {
            sb.Append("<div style='background-color: #fff3f3; border-left: 4px solid #dc3545; padding: 15px; margin-bottom: 30px;'>");
            sb.Append("<strong style='color: #dc3545;'>Payment Overdue:</strong><br/>");
            sb.Append("<span style='font-size: 14px;'>Please settle this invoice immediately to avoid further penalties.</span>");
            sb.Append("</div>");
        }

        // Payment Instructions
        if (bankDetails != null)
        {
            sb.Append("<div style='border-top: 1px solid #eee; padding-top: 20px;'>");
            sb.Append("<h3 style='font-size: 16px; margin-bottom: 10px;'>Payment Instructions</h3>");
            sb.Append("<table style='width: 100%; font-size: 14px;'>");
            sb.Append("<tr>");
            sb.Append("<td style='color: #666;'>Bank Name:</td>");
            sb.Append($"<td>{bankDetails.PrimaryBankName}</td>");
            sb.Append("</tr>");
            sb.Append("<tr>");
            sb.Append("<td style='color: #666;'>Account Name:</td>");
            sb.Append($"<td>{bankDetails.PrimaryAccountName}</td>");
            sb.Append("</tr>");
            sb.Append("<tr>");
            sb.Append("<td style='color: #666;'>Account Number:</td>");
            sb.Append($"<td>{bankDetails.PrimaryAccountNumber}</td>");
            sb.Append("</tr>");
            sb.Append("<tr>");
            sb.Append("<td style='color: #666;'>IFSC Code:</td>");
            sb.Append($"<td style='font-family: monospace;'>{bankDetails.PrimaryIFSCCode}</td>");
            sb.Append("</tr>");
            sb.Append("</table>");
            sb.Append("</div>");
        }

        // Footer
        sb.Append("<div style='margin-top: 40px; text-align: center; color: #999; font-size: 12px; border-top: 1px solid #eee; padding-top: 20px;'>");
        sb.Append($"This is an automated message from {association?.Name}. Please do not reply to this email.");
        sb.Append("</div>");
        
        sb.Append("</div>");

        return sb.ToString();
    }
}
