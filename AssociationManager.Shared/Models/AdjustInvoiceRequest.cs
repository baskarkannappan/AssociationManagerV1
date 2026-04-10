using System.Collections.Generic;

namespace AssociationManager.Shared.Models
{
    public class AdjustInvoiceRequest
    {
        public int InvoiceId { get; set; }
        public List<InvoiceLineItem> LineItems { get; set; } = new();
    }
}
