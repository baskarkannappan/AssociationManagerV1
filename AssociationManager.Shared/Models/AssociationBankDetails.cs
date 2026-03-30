using System;

namespace AssociationManager.Shared.Models;

public class AssociationBankDetails
{
    public int AssociationId { get; set; }
    public int TenantId { get; set; }

    // Primary Account
    public string? PrimaryAccountName { get; set; }
    public string? PrimaryAccountNumber { get; set; }
    public string? PrimaryIFSCCode { get; set; }
    public string? PrimaryBankName { get; set; }
    public string? PrimaryBranchName { get; set; }
    public byte[]? PrimaryQRCode { get; set; }
    public string? PrimaryQRCodeContentType { get; set; }

    // Secondary Account
    public string? SecondaryAccountName { get; set; }
    public string? SecondaryAccountNumber { get; set; }
    public string? SecondaryIFSCCode { get; set; }
    public string? SecondaryBankName { get; set; }
    public string? SecondaryBranchName { get; set; }
    public byte[]? SecondaryQRCode { get; set; }
    public string? SecondaryQRCodeContentType { get; set; }

    public int CreatedBy { get; set; }
    public DateTime CreatedDate { get; set; }
    public int? LastUpdatedBy { get; set; }
    public DateTime? LastUpdatedDate { get; set; }
}
