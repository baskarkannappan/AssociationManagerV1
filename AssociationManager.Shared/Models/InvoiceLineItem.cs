using System;

namespace AssociationManager.Shared.Models;

public class InvoiceLineItem
{
    public int InvoiceLineItemId { get; set; }
    public int InvoiceId { get; set; }
    public string ChargeName { get; set; } = string.Empty;
    public decimal Amount { get; set; }
    public string Description { get; set; } = string.Empty;
    public int? TariffLayerId { get; set; }
    public decimal Rate { get; set; } // Points-in-time snapshot
    public string? TempId { get; set; } // For bulk mapping
}
