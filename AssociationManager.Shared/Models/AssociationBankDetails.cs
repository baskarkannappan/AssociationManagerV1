using System;
using System.ComponentModel.DataAnnotations;

namespace AssociationManager.Shared.Models;

public class AssociationBankDetails
{
    public int AssociationId { get; set; }
    public int TenantId { get; set; }

    // Primary Account
    [Required(ErrorMessage = "Account Name is required")]
    public string? PrimaryAccountName { get; set; }

    [Required(ErrorMessage = "Account Number is required")]
    public string? PrimaryAccountNumber { get; set; }

    [Required(ErrorMessage = "IFSC Code is required")]
    public string? PrimaryIFSCCode { get; set; }

    [Required(ErrorMessage = "Bank Name is required")]
    public string? PrimaryBankName { get; set; }

    [Required(ErrorMessage = "Branch Name is required")]
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

