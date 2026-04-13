using AssociationManager.Data.Interfaces;
using AssociationManager.Services.Interfaces;
using AssociationManager.Shared.Interfaces;
using AssociationManager.Shared.Models;
using QuestPDF.Fluent;
using QuestPDF.Helpers;
using QuestPDF.Infrastructure;
using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Threading.Tasks;

namespace AssociationManager.Services.Implementations;

public class InvoicePdfService : IInvoicePdfService
{
    private readonly IInvoiceRepository _invoiceRepository;
    private readonly IAssociationRepository _associationRepository;
    private readonly IAssetRepository _assetRepository;
    private readonly IOccupancyRepository _occupancyRepository;
    private readonly IPersonRepository _personRepository;
    private readonly IFineService _fineService;
    private readonly ITenantContext _tenantContext;

    public InvoicePdfService(
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

        // QuestPDF License Requirement
        QuestPDF.Settings.License = LicenseType.Community;
    }

    public async Task<byte[]> GenerateInvoicePdfAsync(int invoiceId)
    {
        // 1. Fetch Data
        // Use context for security/multi-tenancy if association context exists
        var associationId = _tenantContext.AssociationId > 0 ? (int?)_tenantContext.AssociationId : null;
        var invoice = await _invoiceRepository.GetByIdAsync(invoiceId, _tenantContext.TenantId, associationId);
        if (invoice == null) throw new Exception("Invoice not found or access denied.");

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
        
        // Dynamic Fine Logic (Matches FinanceService enrichment)
        var itemsList = persistedLineItems.ToList();
        if (invoice.Status != "Paid" && invoice.DueDate < DateTime.UtcNow)
        {
            var fine = await _fineService.CalculateFineAsync(invoice, DateTime.UtcNow);
            if (fine > 0)
            {
                // Check if fine is already in line items (to avoid duplication if already persisted)
                if (!itemsList.Any(l => l.ChargeName.Contains("Penalty") || l.ChargeName.Contains("Fine")))
                {
                    itemsList.Add(new InvoiceLineItem 
                    { 
                        ChargeName = "Late Penalty (Automated)", 
                        Amount = fine, 
                        Description = "Calculated based on association fine rules." 
                    });
                }
            }
        }

        // Shared Total Logic (Principal + Fines)
        decimal principalLineItems = itemsList.Where(l => !l.ChargeName.Contains("Penalty") && !l.ChargeName.Contains("Fine")).Sum(l => l.Amount);
        decimal penaltyLineItems = itemsList.Where(l => l.ChargeName.Contains("Penalty") || l.ChargeName.Contains("Fine")).Sum(l => l.Amount);
        decimal truePrincipal = Math.Max(invoice.Amount, principalLineItems);
        decimal totalAmount = truePrincipal + penaltyLineItems;

        // Formatter Helper
        string FormatCurrency(decimal amount) => amount.ToString("C", new System.Globalization.CultureInfo("en-IN"));

        // 2. Generate PDF using QuestPDF
        var document = Document.Create(container =>
        {
            container.Page(page =>
            {
                page.Size(PageSizes.A4);
                page.Margin(1, Unit.Inch);
                page.PageColor(Colors.White);
                page.DefaultTextStyle(x => x.FontSize(10).FontFamily(Fonts.Verdana));

                page.Header().Row(row =>
                {
                    row.RelativeItem().Column(col =>
                    {
                        col.Item().Text(association?.Name ?? "Association Name").FontSize(20).SemiBold().FontColor(Colors.Blue.Medium);
                        col.Item().Text(association?.Description ?? "Community Management").FontColor(Colors.Grey.Medium);
                    });

                    row.ConstantItem(100).Column(col =>
                    {
                        col.Item().Text("INVOICE").FontSize(16).SemiBold().AlignRight();
                        col.Item().Text($"#{invoice.InvoiceId}").AlignRight();
                    });
                });

                page.Content().PaddingVertical(20).Column(col =>
                {
                    // Billing Details
                    col.Item().Row(row =>
                    {
                        row.RelativeItem().Column(c =>
                        {
                            c.Item().Text("Bill To:").SemiBold();
                            c.Item().Text(residentName);
                            c.Item().Text(assetName);
                        });

                        row.RelativeItem().Column(c =>
                        {
                            c.Item().AlignRight().Text("Invoice Date:").SemiBold();
                            c.Item().AlignRight().Text(invoice.CreatedDate.ToString("MMM dd, yyyy"));
                            c.Item().AlignRight().PaddingTop(5).Text("Due Date:").SemiBold();
                            c.Item().AlignRight().Text(invoice.DueDate.ToString("MMM dd, yyyy"));
                        });
                    });

                    col.Item().PaddingTop(20).Table(table =>
                    {
                        table.ColumnsDefinition(columns =>
                        {
                            columns.ConstantColumn(30);
                            columns.RelativeColumn();
                            columns.ConstantColumn(80);
                        });

                        table.Header(header =>
                        {
                            header.Cell().Element(CellStyle).Text("#");
                            header.Cell().Element(CellStyle).Text("Description");
                            header.Cell().Element(CellStyle).AlignRight().Text("Amount");

                            static IContainer CellStyle(IContainer container) => container.DefaultTextStyle(x => x.SemiBold()).PaddingVertical(5).BorderBottom(1).BorderColor(Colors.Black);
                        });

                        int i = 1;
                        foreach (var item in itemsList)
                        {
                            table.Cell().Element(CellStyle).Text(i++.ToString());
                            table.Cell().Element(CellStyle).Column(c =>
                            {
                                c.Item().Text(item.ChargeName).SemiBold();
                                if (!string.IsNullOrEmpty(item.Description)) c.Item().Text(item.Description).FontSize(8).FontColor(Colors.Grey.Medium);
                            });
                            table.Cell().Element(CellStyle).AlignRight().Text(FormatCurrency(item.Amount));

                            static IContainer CellStyle(IContainer container) => container.PaddingVertical(5);
                        }
                    });

                    col.Item().AlignRight().PaddingTop(10).Row(row =>
                    {
                        row.ConstantItem(100).Text("Total Amount:").FontSize(12).SemiBold();
                        row.ConstantItem(100).AlignRight().Text(FormatCurrency(totalAmount)).FontSize(12).SemiBold().FontColor(Colors.Blue.Medium);
                    });

                     if (invoice.Status == "Overdue")
                    {
                        col.Item().PaddingTop(20).Background(Colors.Red.Lighten5).Padding(10).Text(x =>
                        {
                            x.Span("Important: ").SemiBold().FontColor(Colors.Red.Medium);
                            x.Span("This invoice is past its due date. Please clear your dues immediately to avoid further penalties.");
                        });
                    }

                    // Bank Details / QR Code
                    if (bankDetails != null)
                    {
                        col.Item().PaddingTop(30).Row(row =>
                        {
                            row.RelativeItem().Column(c =>
                            {
                                c.Item().Text("Payment Instructions:").SemiBold();
                                c.Item().Text($"Bank: {bankDetails.PrimaryBankName}");
                                c.Item().Text($"Account Name: {bankDetails.PrimaryAccountName}");
                                c.Item().Text($"A/C Number: {bankDetails.PrimaryAccountNumber}");
                                c.Item().Text($"IFSC Code: {bankDetails.PrimaryIFSCCode}");
                            });

                            if (bankDetails.PrimaryQRCode != null)
                            {
                                row.ConstantItem(100).Column(c =>
                                {
                                    c.Item().Text("Scan to Pay").AlignCenter().FontSize(8).SemiBold();
                                    c.Item().Image(bankDetails.PrimaryQRCode);
                                });
                            }
                        });
                    }
                });

                page.Footer().AlignCenter().Text(x =>
                {
                    x.Span("Page ");
                    x.CurrentPageNumber();
                });
            });
        });

        return document.GeneratePdf();
    }
}
